# common/cd.nix — pull-based continuous deployment. Periodically checks
# the repo for new commits; if there are any, pulls and rebuilds
# automatically. Off unless a host sets cdEnable = true.
#
# Deliberately PULL-based, not push-based via GitHub Actions SSHing in —
# that would mean giving a cloud runner inbound access into your home
# network/tailnet. This way nothing external ever reaches in; the
# machine reaches out to GitHub on its own schedule, same pattern as
# monitoring.nix's health checks.
#
# SECURITY NOTE, worth being honest about: this means anyone who can
# push to your repo can make this machine run arbitrary root-level
# config changes, unattended, on a schedule. Fine for a personal
# single-maintainer repo; think twice before enabling this on a repo
# with other contributors.
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.cdEnable {
  systemd.services.auto-deploy = {
    description = "Pull latest config and rebuild if there are new commits";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig.Type = "oneshot";
    # Runs as root deliberately: nixos-rebuild switch needs root anyway,
    # and it sidesteps needing a NOPASSWD sudo rule for the deploy user.
    # Git auth for a private repo needs to be set up for root
    # specifically — see doc/cd.md.
    path = [ pkgs.git pkgs.curl pkgs.nix ];
    script = ''
      set -uo pipefail
      REPO="/root/dotFiles"

      if [ ! -d "$REPO/.git" ]; then
        echo "No repo at $REPO — see doc/cd.md for one-time setup"
        exit 0
      fi

      cd "$REPO"
      BEFORE="$(git rev-parse HEAD)"

      if ! git pull --ff-only; then
        echo "git pull failed (auth issue? network?) — see doc/cd.md"
        exit 1
      fi

      AFTER="$(git rev-parse HEAD)"

      if [ "$BEFORE" = "$AFTER" ]; then
        echo "No new commits, nothing to do"
        exit 0
      fi

      echo "New commits detected ($BEFORE -> $AFTER), deploying to ${vars.hostname}..."
      ./scripts/install.sh ${vars.hostname}

      if ! nixos-rebuild switch --flake "/etc/nixos#${vars.hostname}"; then
        MESSAGE="Auto-deploy FAILED on ${vars.hostname} ($BEFORE -> $AFTER)"
        echo "$MESSAGE"
        if [ -n "${vars.notifyWebhook}" ]; then
          curl -fsS -X POST -H "Content-Type: text/plain" --data "$MESSAGE" "${vars.notifyWebhook}" || true
        fi
        exit 1
      fi

      echo "Deploy succeeded: $BEFORE -> $AFTER"
    '';
  };

  systemd.timers.auto-deploy = {
    description = "Check for new commits and auto-deploy every 30 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/30";
      Persistent = true;
    };
  };
}
