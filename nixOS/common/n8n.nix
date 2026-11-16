# n8n workflow automation (n8nEnable), via the official Docker image: the
# nixpkgs services.n8n builds from source and hits Node's heap limit.
#
# --network=host, not a port mapping: Docker's published ports bypass the
# NixOS firewall, so a mapping would expose n8n beyond the tailnet.
{ config, pkgs, lib, vars, ... }:

let
  upstreamImage = "docker.n8n.io/n8nio/n8n:latest";
  # npm packages the Code node may require(). Global installs land in
  # /usr/local/lib/node_modules, which Node reaches by walking up from
  # n8n's task runner.
  npmPackages = vars.n8nNpmPackages or [];
  # Community node packages ("name@version"), loaded through
  # N8N_CUSTOM_EXTENSIONS rather than the UI installer, so they're part of
  # the image instead of state in /var/lib/n8n. --legacy-peer-deps: their
  # n8n-workflow peer dependency is n8n's own, and installing it pulls
  # isolated-vm, which needs a compiler toolchain the image lacks.
  communityNodes = vars.n8nCommunityNodes or [];
  communityNodesDir = "/opt/n8n-community-nodes";
  catppuccin = vars.n8nCatppuccin or false;
  customImage = npmPackages != [] || communityNodes != [] || catppuccin;

  # n8n has no theme setting; the stylesheet is linked into the editor UI's
  # index.html after n8n's own CSS so its variable overrides win.
  buildContext = pkgs.runCommand "n8n-image-context" {} ''
    mkdir $out
    cp ${./n8n-catppuccin-mocha.css} $out/catppuccin-mocha.css
    cat > $out/Dockerfile <<'EOF'
    FROM ${upstreamImage}
    USER root
    ${lib.optionalString (npmPackages != []) "RUN npm install -g --omit=dev ${lib.escapeShellArgs npmPackages}"}
    ${lib.optionalString (communityNodes != []) "RUN npm install --prefix ${communityNodesDir} --omit=dev --no-save --legacy-peer-deps ${lib.escapeShellArgs communityNodes}"}
    ${lib.optionalString catppuccin ''
    COPY catppuccin-mocha.css /tmp/catppuccin-mocha.css
    RUN set -e; \
        ui="$(readlink -f /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui)/dist"; \
        mv /tmp/catppuccin-mocha.css "$ui/static/"; \
        sed -i 's#</head>#<link rel="stylesheet" href="/{{BASE_PATH}}/static/catppuccin-mocha.css" nonce="{{CSP_NONCE}}"></head>#' "$ui/index.html"; \
        grep -q catppuccin-mocha.css "$ui/index.html"''}
    USER node
    EOF
  '';
in
lib.mkIf vars.n8nEnable {
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.n8n = {
    image = if customImage then "n8n-custom:latest" else upstreamImage;
    autoStart = true;
    extraOptions = [ "--network=host" ];
    volumes = [ "/var/lib/n8n:/home/node/.n8n" ];
    environment = {
      N8N_PORT = "5678";
      # Secure-only cookies break plain HTTP; Tailscale encrypts the transport.
      N8N_SECURE_COOKIE = "false";
      # Re-enables the Execute Command node (off since n8n 2.0).
      # N8N_NODES_INCLUDE is unreliable (n8n-io/n8n#23439).
      NODES_EXCLUDE = "[]";
      # Built-ins the Code node may require(). child_process and vm are
      # left out on purpose: they'd allow arbitrary shell execution.
      NODE_FUNCTION_ALLOW_BUILTIN = "net,crypto,fs,path,util,querystring,url,os,stream,zlib,dns,http,https,buffer,assert";
    } // lib.optionalAttrs (npmPackages != []) {
      NODE_FUNCTION_ALLOW_EXTERNAL = lib.concatStringsSep "," npmPackages;
    } // lib.optionalAttrs (communityNodes != []) {
      N8N_CUSTOM_EXTENSIONS = "${communityNodesDir}/node_modules";
    };
  };

  systemd.tmpfiles.rules = [
    # 1000 = the container's "node" user; root:root crash-loops with EACCES.
    "d /var/lib/n8n 0755 1000 1000 -"
  ];

  systemd.services.docker-n8n = {
    after = [ "network-online.target" "docker.service" ];
    wants = [ "network-online.target" ];
    restartTriggers = lib.optional customImage buildContext;
  };

  # Builds n8n-custom:latest before the container starts. Docker's layer
  # cache makes this a no-op until the build context or base image changes.
  systemd.services.n8n-image = lib.mkIf customImage {
    description = "Build the customised n8n image";
    requires = [ "docker.service" ];
    after = [ "docker.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    before = [ "docker-n8n.service" ];
    requiredBy = [ "docker-n8n.service" ];
    path = [ config.virtualisation.docker.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "docker build -t n8n-custom:latest ${buildContext}";
  };
}
