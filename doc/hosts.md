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
| `headfull` | `real` | Hyprland desktop (43PR/dotfiles, Firefox, Obsidian client, Spotify, LazyVim) | — |

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
`common/desktop.nix` enables `programs.hyprland` — which, per the official Hyprland-on-NixOS wiki, already handles polkit, the XDG desktop portal, graphics drivers, fonts, dconf, and XWayland on its own. SDDM is the login screen.

[43PR/dotfiles](https://github.com/43PR/dotfiles) provides the actual Hyprland config — deployed via `scripts/post-install.sh` (explicit, run manually after each rebuild — not a home-manager activation script, which only re-runs when the system generation actually changes, silently skipping a no-op rebuild with zero error shown; a real gap hit and fixed during setup). The upstream repo migrated from the old `hyprland.conf` format to Hyprland 0.55+'s new Lua-based config (`hyprland.lua`) partway through this project — the version currently deployed is the Lua one.

`post-install.sh` also fixes several things hardcoded to the original author's own machine that don't apply here — tested against the real repo content, not guessed: `fileManager`/`browser` (was `thunar`/`brave`, now `dolphin`/`firefox` to match what's actually installed), the notification daemon (was `dunst`, now `mako`), a hardcoded Arch-specific polkit path that doesn't exist on NixOS at all (removed — `programs.hyprland` already handles this), the wallpaper daemon (was `awww`, which I couldn't confirm is in mainstream nixpkgs with confidence — now `hyprpaper`, an already-confirmed-available Hyprland-native alternative, with its own config written pointing at a real copied wallpaper), the keyboard layout (was the author's own `us,latam`, now `fr` matching this repo's convention), a wildcard monitor fallback (the upstream config only names the author's own laptop outputs, which won't match a VirtualBox VM's actual display), and every hardcoded reference to the original author's home directory path (found in both `hyprland.lua` and `waybar/config.jsonc`).

Also included via the same `.config/` copy: `waybar`, `rofi`, `kitty`, `wlogout`, `hyprlock`, `btop`, `cava`, `gtk-3.0`, `nwg-look`, `quickshell` (specifically used for the dotfiles' own wallpaper-picker widget), and `spicetify` (Spotify re-theming — files are copied, but not actively applied; it patches the real Spotify install, which doesn't play well with NixOS's read-only `/nix/store` without the dedicated `spicetify-nix` flake). `neofetch` is deliberately skipped in the copy — already managed separately by `home.nix`'s own config, and a home-manager-managed read-only path a plain copy can't write over anyway.

Also configured: PipeWire audio (a real gap — nothing handled audio at all before this; `packages.txt` in the actual dotfiles confirmed `pipewire`/`pipewire-pulse`/`wireplumber` as real requirements), LazyVim (official starter template, cloned into `~/.config/nvim` via a home-manager activation script — this one's fine to stay activation-script-based since it doesn't depend on any external repo's changing format), Firefox, Obsidian (the desktop client, not the sync backend — that's CouchDB on `headless`), Spotify.

**Genuine uncertainty flagged in the code itself**: `rofi` is the plain package, not the `rofi-wayland` fork some Hyprland guides recommend — untested here. Dolphin's "open with" file-association suggestions are known not to work correctly on non-Plasma window managers (an open nixpkgs issue), Hyprland included — it browses/launches files fine regardless.

[← back to overview](./overview.md)