# CLAUDE.md

Multi-host NixOS homelab config (flake) plus tracked desktop dotfiles. One repo builds a separate NixOS system for every directory under `nixOS/hosts/`. Full docs live in `doc/`; start with `doc/overview.md`.

## Layout
- `nixOS/flake.nix` reads every dir in `nixOS/hosts/`, merges `hosts/defaults.nix` with that host's `vars.nix`, and builds `nixosConfigurations.<name>`. Hosts are never registered by hand.
- `nixOS/hosts/<name>/vars.nix` holds per-host values: hostname, username, `targetType` (`"real"` | `"wsl"`), service toggles (`*Enable`), `projectRepos`.
- `nixOS/hosts/defaults.nix` holds shared values. Its comment block lists the keys every host **must** set, and the keys only needed when a given `*Enable` is true.
- `nixOS/common/` has one module per concern, all imported by `common/default.nix`. Every service is gated on a `vars.*Enable` toggle.
- `nixOS/configuration.nix` (real machines) and `nixOS/wsl-configuration.nix` (NixOS-WSL) are the two bases; `targetType` picks one.
- `nixOS/home.nix` is home-manager config shared by every host. `nixOS/home-desktop.nix` is added only when `desktopEnable = true`.
- `dotfiles/` holds the app configs (hypr, waybar, doom, kitty, rofi, mako…). They are **not** linked by Nix: `scripts/post-install.sh` copies them into `~/.config`.
- `scripts/` holds install, post-install, health checks and Jellyfin export/restore.

Note: the layout tree in `doc/overview.md` is out of date. It shows `doom/` and `hypr/` at the repo root, but they live under `dotfiles/`.

## Hosts
`mnemosyne` (real: Jellyfin, Forgejo, SFTP, Homepage), `hermes` (WSL: Transmission, yt-dlp-API), `proteus` (WSL: second main laptop, no services), `athena` (real: Ollama + Open WebUI, n8n), `janus` (real: Hyprland desktop), `janus-vm` (VirtualBox copy of janus).

## Commands
```bash
cd nixOS && nix fmt                                                   # format all .nix (alejandra via treefmt)
cd nixOS && nix build .#checks.x86_64-linux.formatting --no-link      # formatting check (as in CI)
cd nixOS && nix build .#nixosConfigurations.hermes.config.system.build.toplevel --no-link   # build a WSL host
shellcheck scripts/*.sh                                               # lint scripts (as in CI)
```
Deploying on a machine: `./scripts/install.sh <host>`, then `sudo nixos-rebuild switch --flake /etc/nixos#<host>`, then `./scripts/post-install.sh`.

## Conventions and gotchas
- **Adding a service:** create `common/<name>.nix` gated on a new `vars.<name>Enable`, add it to `common/default.nix`, document the toggle in `defaults.nix`'s comment block, and set it explicitly in **every** host's `vars.nix`. A missing key is an evaluation error.
- **Adding a host:** add `hosts/<name>/vars.nix`, plus `hardware-configuration.nix` if `targetType = "real"`. Nothing else changes. See `doc/hosts.md`.
- **Backups (restic) run only on `mnemosyne`**, to its backup drive (`/data/backup`). Every other host must keep `backupEnable = false` and needs no `backupRepo`/`backupPassword`. Don't turn backups on elsewhere.
- Packages missing from nixos-26.05 come from the `nixpkgs-unstable` input, passed to modules as `pkgsUnstable` (e.g. `pkgsUnstable.herdr` in `common/packages.nix`, gated on `herdrEnable`). Keep it to those; everything else stays on stable.
- Keep service-specific values (passwords, sftp keys, backup repo) out of `defaults.nix`. They belong in the vars of the host that enables the service.
- Services are tailnet-only. Never set `openFirewall = true` or expose ports on the public interface; `tailscale0` is the trusted interface (`common/networking.nix`).
- Samba is deliberately disabled on WSL hosts because nmbd crashes under WSL2 NAT.
- Real hosts' `hardware-configuration.nix` files are machine-generated. Don't hand-edit or "fix" them. CI can't build real hosts, so it only fully builds `targetType = "wsl"` hosts. Validate changes to `common/` by building `hermes`.
- Flakes only see git-tracked files. `git add` new files before building or evaluating.
- Secrets: sops-nix is off by default (`secretsEnabled = false`), so some vars hold plaintext placeholders. `couchdbAdminPass` always lands in the Nix store; that's a known nixpkgs limitation (see `doc/secrets.md`). Don't commit real secrets.
- Files use LF line endings (`.gitattributes`). Keep them LF even though the repo is edited from Windows.
- Comments stay short: only a non-obvious *why* (a workaround, a constraint, an upstream bug). No change history, no "per request / fixed / verified" notes, no restating the code, no repeating what `doc/` already says.
- When behavior changes, update the matching `doc/*.md` page.
