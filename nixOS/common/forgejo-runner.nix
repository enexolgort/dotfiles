# Forgejo Actions runner (forgejoRunnerEnable), for the repo's CI in
# .forgejo/workflows. Jobs run straight on the host ("native:host" label),
# so they use its Nix daemon and store instead of installing Nix per job.
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
lib.mkIf (vars.forgejoRunnerEnable or false) {
  # Off by default in older Forgejo releases; explicit so it never depends
  # on the version.
  services.forgejo.settings.actions.ENABLED = true;

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.homelab = {
      enable = true;
      name = vars.hostname;
      url = "http://127.0.0.1:3000";
      # Environment file with TOKEN=<registration token>, created by hand
      # (doc/hosts.md): kept out of the repo and the Nix store.
      tokenFile = vars.forgejoRunnerTokenFile or "/var/lib/forgejo-runner/token.env";
      labels = ["native:host"];
      hostPackages = with pkgs; [
        bash
        coreutils
        curl
        findutils
        gawk
        gitMinimal
        gnugrep
        gnused
        jq
        nodejs # actions/checkout is a JavaScript action
        shellcheck
        wget
        config.nix.package
      ];
    };
  };
}
