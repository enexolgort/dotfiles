# Multi-host setup

## How it works
`flake.nix` reads every subdirectory of `nixOS/hosts/` and builds a `nixosConfigurations.<name>` for each one, automatically — there's no list to maintain by hand. Each host's final config is `hosts/defaults.nix` merged with that host's own `hosts/<name>/vars.nix`, with the host's own values winning on conflict.

Current hosts:

| Host | targetType | Services | Project repos |
|---|---|---|---|
| `mnemosyne` | `real` | Jellyfin, Forgejo (:3000, data on the media drive), SFTP, Homepage dashboard (:8082), Dockhand (Docker UI, :3006) | `transmission-webUi`, `yt-dlp-webUi`, `git-dashboard` (:3004), `backup-health` (:3005) |
| `hermes` | `wsl` | — (Transmission + yt-dlp-API run from its project repos) | `transmission-API` (runs Transmission + its API), `yt-dlp-API` |
| `proteus` | `wsl` | None — second main laptop, NixOS-WSL dev client | — |
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
     dockhandEnable = false;
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
dockhandEnable = true | false;   # Dockhand Docker UI on :3006, see common/dockhand.nix
desktopEnable = true | false;    # Hyprland desktop, see common/desktop.nix + home-desktop.nix
nvidiaEnable = true | false;     # NVIDIA driver, see common/nvidia.nix
gamingEnable = true | false;     # Steam + Proton, see common/gaming.nix
herdrEnable = true | false;      # optional (default false): herdr desktop app, installed by post-install.sh into ~/.local (nix-ld + graphics on)
                                 # herdr-core (hc) is installed by post-install.sh on every host, toggle or not
                                 # herdrEnable also copies dotfiles/herdr/config.toml (Catppuccin Mocha theme) to ~/.config/herdr
claudeEnable = true | false;     # optional (default true): Claude Code, installed by post-install.sh (claude.ai/install.sh) into ~/.local/bin, self-updating (nix-ld on)
```
`common/backups.nix`'s restic paths are conditional on these too — a host with `jellyfinEnable = false` won't try backing up `/var/lib/jellyfin`, since it wouldn't exist there anyway.

## Project repos per host
```nix
projectRepos = [
  "http://mnemosyne:3000/enexolgort/transmission-webUi"
];
```
`install.sh` clones each of these into `projectsDir` (read only from `hosts/defaults.nix`, so a per-host override is ignored; default `/data/projects`) — only for the host you're actually installing, not every host's repos on every machine.

## Local AI (athena) specifically
`common/ai.nix` enables `services.ollama` (the model runner, port `11434`) and `services.open-webui` (the ChatGPT-style frontend for it, default port `8080`) — both real, existing NixOS modules, not something built from scratch. Reachable at `http://<tailscale-ip>:8080` once `aiEnable = true` and rebuilt.

The inference backend comes from the host's `aiBackend` var: `"cpu"` (the default), `"vulkan"`, `"rocm"` or `"cuda"`, which picks `pkgs.ollama-<backend>`. Any GPU backend also turns on `hardware.graphics`. `athena` (AMD BC-250) uses `"vulkan"`, because ROCm doesn't support its gfx1013 GPU.

Open WebUI is unfree in nixpkgs, so the binary cache never has it and every rebuild that bumps it compiles it locally. That frontend build needs more RAM than athena has, because the BC-250 shares its 16 GB with the GPU. athena sets `swapfileGB = 16`, which makes `configuration.nix` add `/var/lib/swapfile`; any real host can set it.

The default model is `qwen3.5:9b`, about 8 GiB at 4K context. The BC-250 maps GPU memory from system RAM through TTM, which caps it at about 7.4 GiB unless `ttm.pages_limit` is raised. athena therefore sets `kernelParams = [ "ttm.pages_limit=4194304" ]` (16 GiB), which needs a reboot to take effect. Through `aiEnvironment`, it sets `OLLAMA_IGPU_ENABLE=1` (Ollama otherwise classifies the BC-250 as an integrated GPU and falls back to CPU), keeps a single model loaded and uses a q8_0 KV cache with flash attention. Models plus KV cache much above ~13 GiB don't fit: `qwen3:14b` (~9 GiB) does, while `gpt-oss:20b` is borderline. For GPU load, athena adds `amdgpu_top` through the optional `extraPackages` var (nixpkgs attribute names), since btop needs ROCm to see AMD GPUs.

athena also sets `bc250Enable = true`, which loads the [bc250-nixos](https://github.com/TesseractCat/bc250-nixos) module (`common/bc250.nix`): nct6687 sensors, the cyan-skillfish GPU governor, zswap, and the CPU core unlock (6c/12t to 8c/16t). The unlock runs in the initrd and reboots once on every cold boot; add `bc250.nocoreunlock` to the kernel command line at the boot menu to skip it for one boot. Stress-test the two extra cores before relying on them.

n8n on athena runs a locally built `n8n-custom:latest` image instead of the upstream one, because it sets two optional vars (`common/n8n.nix`). `n8nNpmPackages` installs npm packages globally in the image and allows them in the Code node through `NODE_FUNCTION_ALLOW_EXTERNAL`. `n8nCatppuccin = true` links `common/n8n-catppuccin-mocha.css` into the editor; it only restyles n8n's dark theme, so pick *Dark* under Settings → Personal → Theme. The `n8n-image` service rebuilds the image before `docker-n8n` starts, and Docker's cache skips the rebuild when nothing changed. The Execute Command node is on for every n8n host (`NODES_EXCLUDE = "[]"`).

Open WebUI on athena sets `openWebuiCatppuccin = true` (`common/ai.nix`). Open WebUI links `/static/custom.css` on every page but wipes its static directory on each start, so the `open-webui-theme` service writes `common/open-webui-catppuccin-mocha.css` there once the server answers `/health`, and reruns whenever Open WebUI restarts. Like the n8n theme, it only restyles the Dark theme (Settings → General → Theme).

## Desktop (`desktopEnable`) specifically
Only `janus` sets `desktopEnable = true` — this describes what the toggle does on any host that turns it on.

`common/desktop.nix` enables `programs.hyprland` — which, per the official Hyprland-on-NixOS wiki, already handles polkit, the XDG desktop portal, graphics drivers, fonts, dconf, and XWayland on its own. SDDM is the login screen.

Your Hyprland config lives in `hypr/` at the repo root — your own, not an external clone — and `scripts/post-install.sh` copies it into `~/.config/hypr` the exact same way it already deploys `doom/` into `~/.config/doom`. Only runs for hosts with `desktopEnable = true`. Safe to re-run any time; it's a plain overwrite copy, same as Doom's.

Also configured: PipeWire audio (`security.rtkit.enable`, `services.pipewire` with ALSA/PulseAudio-compat/WirePlumber), the standard Hyprland companions (`waybar`, `rofi`, `kitty`, `wlogout`, `hyprlock`, `hyprpaper`, `mako` for notifications, `grim`/`slurp` for screenshots, `cliphist`, `pavucontrol`, `brightnessctl`, `playerctl`, `btop`, `cava`, `nwg-look`), Dolphin as the file manager, LazyVim (official starter template, cloned into `~/.config/nvim` via a home-manager activation script — fine to stay activation-script-based since it doesn't depend on any external repo whose format might change), Firefox, Obsidian (the desktop client, not the sync backend — no host currently runs the CouchDB sync backend), Spotify, FileZilla (SFTP client, e.g. for mnemosyne's SFTP upload).

Desktop plumbing on top of that: Bluetooth (BlueZ + `blueman`), `hyprpolkitagent` (polkit auth prompts — `programs.hyprland` enables polkit but no agent), `hypridle` (dim → lock → screen off → suspend, `dotfiles/hypr/hypridle.conf`), `upower`, `libnotify`, `nm-connection-editor`, and the user added to the `networkmanager`/`video` groups so WiFi and backlight changes don't need a password.

The controllers, all reachable from waybar and from a shortcut (see [hyprland-keybinds.md](./hyprland-keybinds.md)):
- **WiFi** — waybar's network module; click opens `hypr/scripts/wifi-menu.sh` (a `rofi -dmenu` network picker over `nmcli`, prompts for the password on new secured networks), right-click opens `nm-connection-editor`. `nm-applet --indicator` also sits in the tray.
- **Audio** — waybar's volume module; scroll = ±5%, right-click = mute, click = `pavucontrol`. Media/volume/mic-mute hardware keys go through `wpctl`/`playerctl`.
- **Bluetooth** — waybar's bluetooth module and `blueman-applet` in the tray; click opens `blueman-manager`.
- **Launcher / dmenu** — `rofi -show drun` for apps, `rofi -dmenu` for the clipboard, opacity and WiFi pickers.

## NVIDIA and gaming (janus)
janus is a hybrid laptop (iGPU + RTX 5070). `common/nvidia.nix` loads the NVIDIA driver with the open kernel modules, which Blackwell cards require. When the host sets `nvidiaPrime`, it also turns on PRIME offload: the iGPU drives the screen and the NVIDIA GPU renders only what you ask it to. Leave `nvidiaPrime` out on a desktop with a single NVIDIA card.

`nvidiaPrime` in `hosts/janus/vars.nix` holds **placeholder** bus IDs. Before the first rebuild, run `lspci | grep -E "VGA|3D"` on janus and convert each address to decimal `PCI:bus:device:function` (e.g. `01:00.0` → `PCI:1:0:0`). Use `amdgpuBusId` instead of `intelBusId` if the CPU is AMD.

- Run any app on the NVIDIA GPU with `nvidia-offload <app>`, e.g. `nvidia-offload blender`.
- `common/gaming.nix` enables Steam with Valve's Proton built in, adds GE-Proton (`proton-ge-bin`), and enables `gamemode`. On a PRIME host, Steam starts with the offload variables set, so its games render on the NVIDIA GPU without per-game launch options. Pick GE-Proton per game under Properties → Compatibility.

Waybar also gained Hyprland workspaces, battery (hidden on machines without one) and a system tray — without the tray nm-applet/blueman-applet had nowhere to appear. The GPU module is defined but left off the bar (its script needs `nvtop`, not installed).

**Genuine uncertainty flagged in the code itself**: Dolphin's "open with" file-association suggestions are known not to work correctly on non-Plasma window managers (an open nixpkgs issue), Hyprland included — it browses/launches files fine regardless.

[← back to overview](./overview.md)