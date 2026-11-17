# Forgejo Actions runner (forgejoRunnerEnable), for the repo's CI in
# .forgejo/workflows. Jobs run straight on the host ("native:host" label),
# so they use its Nix daemon and store instead of installing Nix per job.
{
  config,
  lib,
  pkgs,
  vars,
  ...
}: let
  # TOKEN=<registration token>, kept out of the repo and the Nix store.
  tokenFile = vars.forgejoRunnerTokenFile or "/var/lib/forgejo-runner/token.env";
  forgejo = config.systemd.services.forgejo;
in
  lib.mkIf (vars.forgejoRunnerEnable or false) {
    # Off by default in older Forgejo releases; explicit so it never depends
    # on the version.
    services.forgejo.settings.actions.ENABLED = true;

    # Creates the registration token once, so no manual step is needed. Runs
    # with forgejo's environment and credentials: without its secrets the CLI
    # would generate new ones and write them into app.ini.
    systemd.services.forgejo-runner-token = {
      description = "Create the Forgejo Actions runner registration token";
      requires = ["forgejo.service"];
      after = ["forgejo.service"];
      before = ["gitea-runner-homelab.service"];
      requiredBy = ["gitea-runner-homelab.service"];
      unitConfig.ConditionPathExists = "!${tokenFile}";
      environment = removeAttrs forgejo.environment ["PATH"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        inherit (forgejo.serviceConfig) User LoadCredential;
        UMask = "0077";
        ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o ${forgejo.serviceConfig.User} ${dirOf tokenFile}";
      };
      script = ''
        token="$(${lib.getExe config.services.forgejo.package} forgejo-cli actions generate-runner-token)"
        printf 'TOKEN=%s\n' "$token" > ${tokenFile}
      '';
    };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.homelab = {
        enable = true;
        name = vars.hostname;
        url = "http://127.0.0.1:3000";
        inherit tokenFile;
        # "docker" is for repos whose jobs expect a container (e.g. bacon-buddy).
        labels = ["native:host" "docker:docker://node:20-bookworm"];
        # Host network: job containers then resolve the tailnet name in Forgejo's
        # ROOT_URL and reach the runner's cache server.
        settings.container.network = "host";
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
