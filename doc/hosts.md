# Multi-host setup

## How it works
`flake.nix` reads every subdirectory of `nixOS/hosts/` and builds a `nixosConfigurations.<name>` for each one, automatically — there's no list to maintain by hand. Each host's final config is `hosts/defaults.nix` merged with that host's own `hosts/<name>/vars.nix`, with the host's own values winning on conflict.

Current hosts:

| Host | targetType | Services | Project repos |
|---|---|---|---|
| `mnemosyne` | `real` | Jellyfin, Forgejo (:3000, data on the media drive), SFTP, Homepage dashboard (:8082) | `transmission-webUi`, `yt-dlp-webUi` |
| `hermes` | `wsl` | — (Transmission + yt-dlp-API run from its project repos) | `transmission-API` (runs Transmission + its API), `yt-dlp-API` |
| `athena` | `real` | Ollama + Open WebUI (local AI), n8n (Docker) | — |
| `janus` | `real` | None — the Hyprland desktop client (`desktopEnable = true`): browser + SSH into the rest over Tailscale | — |
| `janus-vm` | `real` | Same as `janus`, as a VirtualBox VM (BIOS/GRUB, label-based `hardware-configuration.nix` committed for real) | — |

## Installing/updating a specific host
```bash
cd ~/dotFiles
./scripts/install.sh mnemosyne        # or hermes, or athena
```
Omit the argument for an interactive menu instead. This copies the whole `nixOS/` tree into `/etc/nixos` (every host's files need to exist for the flake to evaluate at all, even though only one host actually gets built) and clones that host's `projectRepos`.

Then, on that machine:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#mnemosyne
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
     homepageEnable = false;
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
homepageEnable = true | false;   # fleet dashboard on :8082, see common/homepage.nix
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

## Local AI (athena) specifically
`common/ai.nix` enables `services.ollama` (the model runner, port `11434`) and `services.open-webui` (the ChatGPT-style frontend for it, default port `8080`) — both real, existing NixOS modules, not something built from scratch. Reachable at `http://<tailscale-ip>:8080` once `aiEnable = true` and rebuilt.

CPU-only by default (`acceleration = false` in `common/ai.nix`). If `athena` has a compatible GPU, tell me which one and I'll wire up the right acceleration option — CPU inference works but is genuinely slow beyond small models.

## Desktop (`desktopEnable`) specifically
Only `janus` sets `desktopEnable = true` — this describes what the toggle does on any host that turns it on.

`common/desktop.nix` enables `programs.hyprland` — which, per the official Hyprland-on-NixOS wiki, already handles polkit, the XDG desktop portal, graphics drivers, fonts, dconf, and XWayland on its own. SDDM is the login screen.

Your Hyprland config lives in `hypr/` at the repo root — your own, not an external clone — and `scripts/post-install.sh` copies it into `~/.config/hypr` the exact same way it already deploys `doom/` into `~/.config/doom`. Only runs for hosts with `desktopEnable = true`. Safe to re-run any time; it's a plain overwrite copy, same as Doom's.

Also configured: PipeWire audio (`security.rtkit.enable`, `services.pipewire` with ALSA/PulseAudio-compat/WirePlumber), the standard Hyprland companions (`waybar`, `rofi`, `kitty`, `wlogout`, `hyprlock`, `hyprpaper`, `mako` for notifications, `grim`/`slurp` for screenshots, `cliphist`, `pavucontrol`, `brightnessctl`, `playerctl`, `btop`, `cava`, `nwg-look`), Dolphin as the file manager, LazyVim (official starter template, cloned into `~/.config/nvim` via a home-manager activation script — fine to stay activation-script-based since it doesn't depend on any external repo whose format might change), Firefox, Obsidian (the desktop client, not the sync backend — no host currently runs the CouchDB sync backend), Spotify.

Desktop plumbing on top of that: Bluetooth (BlueZ + `blueman`), `hyprpolkitagent` (polkit auth prompts — `programs.hyprland` enables polkit but no agent), `hypridle` (dim → lock → screen off → suspend, `dotfiles/hypr/hypridle.conf`), `upower`, `libnotify`, `nm-connection-editor`, and the user added to the `networkmanager`/`video` groups so WiFi and backlight changes don't need a password.

The controllers, all reachable from waybar and from a shortcut (see [hyprland-keybinds.md](./hyprland-keybinds.md)):
- **WiFi** — waybar's network module; click opens `hypr/scripts/wifi-menu.sh` (a `rofi -dmenu` network picker over `nmcli`, prompts for the password on new secured networks), right-click opens `nm-connection-editor`. `nm-applet --indicator` also sits in the tray.
- **Audio** — waybar's volume module; scroll = ±5%, right-click = mute, click = `pavucontrol`. Media/volume/mic-mute hardware keys go through `wpctl`/`playerctl`.
- **Bluetooth** — waybar's bluetooth module and `blueman-applet` in the tray; click opens `blueman-manager`.
- **Launcher / dmenu** — `rofi -show drun` for apps, `rofi -dmenu` for the clipboard, opacity and WiFi pickers.

Waybar also gained Hyprland workspaces, battery (hidden on machines without one) and a system tray — without the tray nm-applet/blueman-applet had nowhere to appear. The GPU module is defined but left off the bar (its script needs `nvtop`, not installed).

**Genuine uncertainty flagged in the code itself**: Dolphin's "open with" file-association suggestions are known not to work correctly on non-Plasma window managers (an open nixpkgs issue), Hyprland included — it browses/launches files fine regardless.

[← back to overview](./overview.md)