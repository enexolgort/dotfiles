# Multi-host setup

## How it works
`flake.nix` reads every subdirectory of `nixOS/hosts/` and builds a `nixosConfigurations.<name>` for each one, automatically — there's no list to maintain by hand. Each host's final config is `hosts/defaults.nix` merged with that host's own `hosts/<name>/vars.nix`, with the host's own values winning on conflict.

Current hosts:

| Host | targetType | Services | Project repos |
|---|---|---|---|
| `dusty` | `real` | Jellyfin, SFTP | `transmission-webUi` |
| `headless` | `wsl` | Obsidian (CouchDB), Forgejo, n8n | `transmission-API` |
| `scrapy` | `wsl` | Ollama + Open WebUI (local AI) | — |
| `shadow` | `real` | Monitoring hub: Prometheus, Grafana, restic REST server (offsite backup target for the other three) | — |
| `headfull` | `real` | Hyprland desktop (Firefox, Obsidian client, Spotify, LazyVim, 43PR/dotfiles rice) | — |

## Installing/updating a specific host
```bash
cd ~/dotFiles
./scripts/install.sh dusty        # or headless, or scrapy
```
Omit the argument for an interactive menu instead. This copies the whole `nixOS/` tree into `/etc/nixos` (every host's files need to exist for the flake to evaluate at all, even though only one host actually gets built) and clones that host's `projectRepos`.

Then, on that machine:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#dusty
```
(swap in whichever host you're actually on)

`rebuild` (the shell alias from `home.nix`) still works without needing the host name explicitly — `nixos-rebuild` auto-detects it from the machine's own current hostname.

## Adding a new host
1. Create `nixOS/hosts/<name>/vars.nix`:
   ```nix
   {
     hostname = "yourhostname";
     username = "youruser";
     gitEmail = "you@yourhostname.local";
     targetType = "real"; # or "wsl"

     jellyfinEnable = false;
     obsidianEnable = false;
     gitServerEnable = false;
     aiEnable = false;
     sftpEnable = false;
     n8nEnable = false;
     monitoringHubEnable = false;
     desktopEnable = false;

     projectRepos = [ ];
   }
   ```
2. If `targetType = "real"`, also add `nixOS/hosts/<name>/hardware-configuration.nix` — a placeholder until you run `nixos-generate-config` on that actual machine (see [deploy-real-machine.md](./deploy-real-machine.md)). WSL hosts don't need this file at all.
3. Only override what's actually different from `hosts/defaults.nix` — you don't need to repeat `mediaDir`, `sftpDir`, timezone, etc. unless this host genuinely needs something different.
4. `./scripts/install.sh <name>` on that machine, then the usual `nixos-rebuild switch --flake /etc/nixos#<name>`.

## Service toggles
Each host's `vars.nix` sets these directly — no interactive prompting, no shared on/off switch affecting every machine:
```nix
jellyfinEnable = true | false;
obsidianEnable = true | false;   # CouchDB backend for Obsidian Self-hosted LiveSync
gitServerEnable = true | false;  # Forgejo
aiEnable = true | false;         # Ollama + Open WebUI, see common/ai.nix
sftpEnable = true | false;       # chrooted upload account, see common/sftp.nix
n8nEnable = true | false;        # workflow automation, see common/n8n.nix
monitoringHubEnable = true | false; # Prometheus+Grafana+restic REST server, see common/monitoring-hub.nix
desktopEnable = true | false;    # Hyprland desktop, see common/desktop.nix + home-desktop.nix
```
`common/backups.nix`'s restic paths are conditional on these too — a host with `jellyfinEnable = false` won't try backing up `/var/lib/jellyfin`, since it wouldn't exist there anyway.

## Project repos per host
```nix
projectRepos = [
  "https://github.com/enexolgort/transmission-webUi"
];
```
`install.sh` clones each of these into that host's `projectsDir` (from `hosts/defaults.nix`, default `/data/projects`) — only for the host you're actually installing, not every host's repos on every machine.

## Local AI (scrapy) specifically
`common/ai.nix` enables `services.ollama` (the model runner, port `11434`) and `services.open-webui` (the ChatGPT-style frontend for it, default port `8080`) — both real, existing NixOS modules, not something built from scratch. Reachable at `http://<tailscale-ip>:8080` once `aiEnable = true` and rebuilt.

CPU-only by default (`acceleration = false` in `common/ai.nix`). If `scrapy` has a compatible GPU, tell me which one and I'll wire up the right acceleration option — CPU inference works but is genuinely slow beyond small models.

## Monitoring hub (shadow) specifically
`common/monitoring-hub.nix` enables Prometheus (port `9090`), Grafana (port `3000`), and a restic REST server (port `8000`) — the last of these is the actual offsite backup *target* the other hosts' `backupRepo` values point at (e.g. `rest:http://<shadow-tailscale-ip>:8000/dusty`), not another client backing itself up. `shadow`'s own `backupEnable` stays `false` for exactly that reason.

Not yet wired up (deliberately, as a separate follow-up): `node_exporter` on `dusty`/`headless`/`scrapy` (so Prometheus/Grafana actually have something to scrape), and pointing those hosts' `notifyWebhook` at whatever `shadow`'s webhook receiver turns out to be — likely a small Docker container rather than a native NixOS module, same pattern as `transmission-API`/`transmission-webUi`.

## Desktop (headfull) specifically
`common/desktop.nix` enables `programs.hyprland` — which, per the official Hyprland-on-NixOS wiki, already handles polkit, the XDG desktop portal, graphics drivers, fonts, dconf, and XWayland on its own. SDDM is the login screen. The [43PR/dotfiles](https://github.com/43PR/dotfiles) "rice" is applied via `home-desktop.nix`'s activation script — cloned once, then its `.config/*` subdirectories are copied into the real `~/.config/` (not the whole repo, since it also has README screenshots and wallpapers at the root that aren't config). Same pattern already established for the Doom Emacs bootstrap in `home.nix`.

Also included: LazyVim (official starter template, cloned into `~/.config/nvim` the same way), Firefox, Obsidian (the desktop client, not the sync backend — that's CouchDB on `headless`), Spotify, plus the standard companions any real Hyprland setup needs that weren't in the dotfiles repo itself (`mako` for notifications, `hyprlock`/`hyprpaper`, `grim`/`slurp` for screenshots, `cliphist`, `pavucontrol`, `thunar`).

**Deliberately not wired up**: `spicetify` (present in the dotfiles' `.config` but not applied here) — it patches the actual Spotify installation's files, which doesn't play well with NixOS's read-only `/nix/store` without the community `spicetify-nix` flake built specifically for that. A real follow-up if wanted, not something to fake.

**Genuine uncertainty flagged in the code itself**: `quickshell` (referenced in the dotfiles) isn't in the package list — couldn't confirm the exact nixpkgs package name/availability with confidence, so it's left as a comment to verify rather than guessed at. `rofi` is the plain package, not the `rofi-wayland` fork some Hyprland guides recommend — untested here.

See [headfull-keybinds.md](./headfull-keybinds.md) for the full keyboard shortcuts reference, pulled directly from the actual dotfiles config.

[← back to overview](./overview.md)