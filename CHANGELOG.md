# Changelog

All notable changes to this repo are documented here, newest first.
Format follows [Keep a Changelog](https://keepachangelog.com/); versioning
follows [SemVer](https://semver.org/), applied to the fleet as a whole:

- **major**: a change that needs manual work on existing machines beyond the
  usual deploy (stays `0` while the setup is still taking shape);
- **minor**: new hosts, services, toggles or desktop features, and breaking
  changes while on `0.x` (flagged under **Breaking**);
- **patch**: fixes only.

Each version is a `vX.Y.Z` tag on its last commit — see "Tagging a release"
at the bottom. Versions before 0.10.0 were reconstructed from the history.

## Unreleased

### Added
- n8n: `n8n/workflows/host-health.json`, a workflow that checks SSH and
  every service on all hosts every 15 minutes and POSTs to a webhook when
  the set of failing checks changes.
- **Forgejo Actions CI** on mnemosyne: `forgejoRunnerEnable` toggle
  (`common/forgejo-runner.nix`) runs a `forgejo-runner` with the
  `native:host` label, so jobs use the host's Nix. Its registration token
  is created on first deploy by the `forgejo-runner-token` service
  (`forgejo-cli actions generate-runner-token`) and kept outside the repo
  and the Nix store. Forgejo's Actions are enabled explicitly.
- treefmt lints: deadnix (lambda arguments kept) and statix, alongside
  alejandra.

### Changed
- **Breaking:** CI moved from `.github/workflows` to
  `.forgejo/workflows/ci.yml`; it no longer installs Nix per job. It needs
  mnemosyne rebuilt with the runner.
- Every `.nix` file formatted by `nix fmt` (layout only, plus statix
  rewrites such as `inherit (vars) initialPassword`). Host derivations are
  unchanged.

### Fixed
- The formatting check failed on every file, since nothing had been
  formatted. `hardware-configuration.nix` files are now excluded from
  treefmt, as they're machine-generated.

## [0.11.0] — 2026-11-16

### Added
- n8n: optional `n8nCommunityNodes` var installs pinned community node
  packages into the custom image and loads them through
  `N8N_CUSTOM_EXTENSIONS`. athena gets `n8n-nodes-forgejo@0.2.0` (Forgejo
  node and credential).

### Fixed
- mnemosyne: yt-dlp-API on hermes can push over SFTP; its key
  (`yt-dlp-api@hermes`) is now in `sftpPublicKeys`.

## [0.10.0] — 2026-11-16

### Added
- **Hermes Agent** (Nous Research) on athena: new `hermesAgentEnable` toggle
  (default `false`). `scripts/post-install.sh` runs its upstream installer
  non-interactively, without Chromium or the computer-use driver; nix-ld is
  turned on for it. Configured once with `hermes setup` against Ollama.
- `CHANGELOG.md` and version tags for the whole history.

### Changed
- athena: Ollama context raised from 32K to 64K (`OLLAMA_CONTEXT_LENGTH`),
  the minimum Hermes Agent accepts. `qwen3.5:9b` still fits fully on the GPU.

### Fixed
- Upstream installers (Hermes Agent) failed when appending a PATH line to
  home-manager's read-only `.bashrc`, `.profile` and `.bash_profile`. All
  three now contain the guarded `~/.local/bin` PATH line those installers
  look for. `post-install.sh` checks Hermes's own completion marker, so an
  interrupted install is retried.

## [0.9.0] — 2026-11-15

### Added
- athena (AMD BC-250) local AI:
  - `aiBackend` var picks `pkgs.ollama-<backend>`; athena uses `vulkan`
    (ROCm doesn't support gfx1013), with `OLLAMA_IGPU_ENABLE=1` because
    Ollama otherwise skips the BC-250 as an integrated GPU.
  - Model `qwen3.5:9b` (was `qwen2.5:0.5b`), single loaded model, q8_0 KV
    cache, flash attention, via the new `aiEnvironment` var.
  - `kernelParams` var; athena raises `ttm.pages_limit` so the GPU can use
    all 16 GiB.
  - `swapfileGB` var; athena gets 16 GiB so Open WebUI's local build isn't
    OOM-killed.
  - [bc250-nixos](https://github.com/TesseractCat/bc250-nixos) flake input
    behind `bc250Enable`: CPU core unlock (6c/12t to 8c/16t), GPU governor,
    nct6687 sensors, zswap.
  - `extraPackages` var (nixpkgs attribute names); athena gets `amdgpu_top`,
    `pciutils` and `lm_sensors`.
- **SearXNG** on `:8888` for every `aiEnable` host, wired into Open WebUI's
  web search and usable from n8n agents. Secret key generated on first boot.
- **n8n**: optional locally built image with npm packages for the Code node
  (`n8nNpmPackages`) and a Catppuccin Mocha dark theme (`n8nCatppuccin`).
- **Open WebUI**: optional Catppuccin Mocha dark theme
  (`openWebuiCatppuccin`), written as `custom.css` after each start.
- [openwebui-usage](http://mnemosyne:3000/enexolgort/openwebui-usage)
  token-usage dashboard on athena (`:3007`) and its *AI usage* Homepage tile.
- Herdr homelab-services plugin (`dotfiles/herdr/plugins`).

### Changed
- SearXNG uses Bing only (plus Wikipedia/Wikidata): from athena, Google
  returns nothing, DuckDuckGo/Startpage answer with CAPTCHAs and Brave
  rate-limits. No default language, since Bing returns unrelated results
  with one set.
- Docs: `projectRepos` examples point at Forgejo; `projectsDir` is read only
  from `defaults.nix`.

### Fixed
- Shell scripts are tracked as executable again.

## [0.8.0] — 2026-11-14

### Added
- Forgejo themed Catppuccin Mocha (mauve); the CSS is copied as root rather
  than linked through tmpfiles.

### Changed
- Claude Code is on every host by default (`claudeEnable = true` in
  `defaults.nix`); enabled on hermes and athena first.
- Non-login bash shells (herdr panes, terminal tabs) load home-manager's
  session variables.

### Fixed
- nixpkgs renames: `services.ollama.acceleration` removed (now the
  `ollama-cpu` package) and deprecated `xorg.*` package names.

## [0.7.0] — 2026-11-12

### Added
- **proteus** host (WSL, second main laptop).
- janus: NVIDIA driver (`nvidiaEnable`) and Steam (`gamingEnable`);
  FileZilla on desktop hosts.
- **herdr**: `herdrEnable` toggle installs the desktop app with its upstream
  installer; herdr-core is installed on every host. Tracked herdr config in
  Catppuccin Mocha, semi-transparent like kitty.
- `claudeEnable` toggle; Claude Code installed with its native installer
  (not nixpkgs), with nix-ld.
- The Windows SSH key is authorized for the main user on every host.
- GitHub CLI on every host; python3 in `home.nix` for herdr's Claude Code
  hook.
- **Dockhand** Docker UI on mnemosyne (`:3006`).

### Changed
- SSH and Samba are tailnet-only.
- `post-install.sh` keeps going when the Doom install or sync fails.

### Fixed
- Service tests: yt-dlp-API on hermes, transmission-API on `:3002`, right
  repos cloned per host, every service covered.
- Duplicate btop and Doom install removed.

## [0.6.0] — 2026-11-09

### Added
- **git-dashboard** cloned and run on mnemosyne, with a Homepage tile.
- Backup health on Homepage and in waybar.
- waybar: fleet-status module (from the Homepage API) and wttr.in weather.
- Hyprland: rofi menus for SSH and homelab services.
- `CLAUDE.md`; comments trimmed repo-wide.

### Changed
- **Breaking:** Forgejo moved from hermes to mnemosyne, data on the
  backed-up media HDD; local Docker containers can reach it on `:3000`.
- Homepage tiles show each service's port.
- `install.sh` builds Compose projects on first clone.

### Removed
- **Breaking:** argus host and the monitoring hub.

### Fixed
- wlogout falls back to Hyprland exit when `uwsm stop` is refused.
- mnemosyne: transmission-webUi repo name in `projectRepos`.

## [0.5.0] — 2026-11-07

### Added
- **janus-vm** host: VirtualBox copy of janus (software GL, CPU lock screen
  and wallpaper).
- `ytdlpEnable` (yt-dlp CLI on hermes); yt-dlp-webUi cloned on mnemosyne;
  Homepage tiles for yt-dlp-API and the Video UI.
- Catppuccin Mocha desktop: hyprlock, waybar, kitty, rofi, Qt/KDE apps
  (Dolphin), GTK, SDDM, wlogout, mako; Posy's cursor; wallpaper images.
- Desktop essentials: dialogs, USB, OSD, default apps; square-tile power
  menu with uptime; waybar calendar popup; Bluetooth button.
- Apps on desktop hosts: Claude Code (replacing VS Code), Hoppscotch,
  Blender, Discord, OBS Studio.

### Changed
- `install.sh` pulls already-cloned project repos and rebuilds their Docker
  images; a real `hardware-configuration.nix` in the repo wins.
- Hyprland: AZERTY workspace keys, arrow keys for focus/move/resize, lock on
  Super+L, new windows not maximized, waybar space reserved.
- `post-install.sh` refuses to run as root.

### Fixed
- Hyprland 0.55 Lua-config breakages (monitor scale, `hyprctl dispatch`);
  uwsm enabled so the SDDM session starts.
- Wallpaper falls back to swaybg when hyprpaper fails.
- Bluetooth button notifies instead of erroring without an adapter.

## [0.4.0] — 2026-11-04

### Added
- **janus** desktop host (Hyprland).
- **Homepage** fleet dashboard (`:8082`) on mnemosyne.
- n8n on athena; yt-dlp-API cloned on hermes.

### Changed
- **Breaking:** NixOS upgraded to 26.05.

### Fixed
- sftp: `fsType = "none"` on the media bind mount, required since 26.05.

## [0.3.0] — 2026-10-23

### Changed
- **Breaking:** hosts renamed: dusty → **mnemosyne**, headless →
  **hermes**, shadow → argus; new **athena** host. headfull dropped.
- hermes: Forgejo replaces Obsidian/CouchDB.
- mnemosyne uses systemd-boot; `install.sh` skips hardware configs of
  removed hosts.

### Removed
- scrapy host; Forgejo removed from headless.

### Fixed
- dusty backup drive UUID.

## [0.2.1] — 2026-09-08

### Changed
- n8n disabled on headless.

### Notes
- A `vps` host (Ollama + Open WebUI, GRUB on `/dev/sda`, pinned to
  nixos-26.05) and `fix-vps-hardware-config.sh` were added and removed the
  same day; nothing of it remains.

## [0.2.0] — 2026-08-14

### Added
- `install.sh --regen-hardware`.
- nm-applet for graphical network management.
- `.gitattributes` enforcing LF line endings.
- Own tracked Hyprland config under `dotfiles/hypr`, same pattern as Doom
  (after trying the 43PR/dotfiles integration).
- dusty: real `hardware-configuration.nix` and drive UUIDs.

### Changed
- Bootloader is per host: GRUB for headfull (legacy BIOS VM), systemd-boot
  for dusty and shadow.
- Desktop app setup moved from `home.activation` to `post-install.sh`;
  neofetch skipped in the dotfiles copy loop.
- Docs: GNOME and gui-start/gui-stop dropped; personal-project disclaimer.

### Removed
- GNOME and GDM; SDDM + Hyprland is the only desktop stack.

### Fixed
- `nix eval --raw` crashed on the boolean `desktopEnable`, silently skipping
  dotfiles deployment.
- PipeWire gap and missing desktop packages.
- Doom install: invalid `--no-fonts` flag removed; source path moved to
  `dotfiles/doom`.

## [0.1.0] — 2026-08-10

First version.

### Added
- NixOS flake that builds one system per directory under `nixOS/hosts/`,
  merging `hosts/defaults.nix` with each host's `vars.nix`.
- Hosts: dusty, shadow, headfull, headless, scrapy.
- One module per service in `nixOS/common/`, each behind a `*Enable` toggle:
  Jellyfin, CouchDB, Forgejo, Ollama + Open WebUI, n8n, SFTP, Docker,
  restic backups, monitoring.
- home-manager config and tracked desktop dotfiles.
- `scripts/`: install, post-install, health checks, Jellyfin export/restore.
- README with the homelab architecture diagram.

### Fixed
- Thunar through `programs.thunar.enable` (its package moved under `xfce`).

---

## Tagging a release

1. Move the "Unreleased" entries under a new `## [x.y.z] — YYYY-MM-DD`
   header.
2. Commit, then tag and push:

```bash
git tag -a v0.12.0 -m "v0.12.0"
git push && git push --tags
```
