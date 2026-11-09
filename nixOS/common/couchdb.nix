# CouchDB on :5984 for Obsidian's Self-hosted LiveSync plugin (obsidianEnable).
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.obsidianEnable {
  services.couchdb = {
    enable = true;
    bindAddress = "0.0.0.0"; # legacy [httpd]; 3.x listens via chttpd below
    adminUser = vars.couchdbAdminUser;
    adminPass = vars.couchdbAdminPass; # ends up in the Nix store, see doc/secrets.md
    extraConfig = {
      chttpd = {
        enable_cors = "true";
        bind_address = "0.0.0.0";
      };
      cors = {
        origins = "app://obsidian.md, capacitor://localhost, http://localhost";
        credentials = "true";
        headers = "accept, authorization, content-type, origin, referer";
        methods = "GET,PUT,POST,HEAD,DELETE";
        max_age = "3600";
      };
    };
  };

  systemd.services.couchdb = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
