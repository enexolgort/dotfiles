# Deploy: NixOS-WSL

Skip this if you're only deploying to the real machine — see [deploy-real-machine.md](./deploy-real-machine.md) instead.

## One-time setup, on Windows

1. In an elevated PowerShell:
   ```powershell
   wsl --install --no-distribution
   ```
   (skip if you already have WSL2 itself set up — this just ensures the WSL2 platform exists, without installing any particular distro yet)

2. Download the latest NixOS-WSL release tarball from https://github.com/nix-community/NixOS-WSL/releases (the `nixos-wsl.tar.gz` asset).

3. Import it as a new WSL distro:
   ```powershell
   wsl --import NixOS $env:USERPROFILE\NixOS-WSL\ path\to\nixos-wsl.tar.gz --version 2
   wsl -d NixOS
   ```
   You're now inside a real, minimal NixOS system running under WSL2.

4. From inside that NixOS-WSL shell, get git and clone your dotfiles repo:
   ```bash
   nix-shell -p git
   git clone <your-dotfiles-repo-url> ~/dotFiles
   cd ~/dotFiles
   ./scripts/install.sh hermes
   sudo nixos-rebuild switch --flake /etc/nixos#hermes
   ```
   (swap `hermes` for whichever WSL-`targetType` host you're actually deploying)

5. Continue with [first-boot-setup.md](./first-boot-setup.md).

Your **existing** WSL distro (the Ubuntu-or-whatever one you were using before, with the plain `nix` package manager) is unaffected and still fine to keep around for general editing/git work — `NixOS` shows up as a separate distro alongside it in `wsl -l -v`.

## USB devices from Windows (usbip)

A WSL host can attach USB devices plugged into Windows, such as proteus's T-Beam Supreme, by listing their usbipd bus IDs in `usbipAutoAttach` (`vars.nix`; proteus: `["2-1"]`). This turns on NixOS-WSL's `wsl.usbip` and adds the user to `dialout` so serial ports (`/dev/ttyACM*`, `/dev/ttyUSB*`) open without sudo.

On Windows, once: install [usbipd-win](https://github.com/dorssel/usbipd-win) (`winget install usbipd`), find the bus ID with `usbipd list`, and share it from an admin PowerShell with `usbipd bind --busid 2-1`. The bus ID follows the physical port, so plugging the device into another port changes it. Log out and back in after the first rebuild to pick up `dialout`.

## Known gotcha: nixos-wsl-utils build failure
If `nixos-rebuild` fails trying to build `nixos-wsl-utils` with a Cargo/Rust `edition2024` error, the root cause is that **our own `nixpkgs` pin is too old** — `nixos-wsl`'s NixOS module builds that utility using *our* nixpkgs (regardless of whether `nixos-wsl`'s own flake input follows ours or has a separate pin; that only affects nixos-wsl's own flake-level evaluation, not what pkgs its NixOS module resolves to). `nixos-24.11` only ever received security backports, never a newer Cargo, so this specific build was never going to succeed on it.

**Fix**: bump `nixpkgs.url` (and `home-manager.url` to match) in `flake.nix` to a current stable branch — e.g. `nixos-25.11` — then delete `flake.lock` and let it regenerate:
```bash
rm ~/dotFiles/nixOS/flake.lock
cd ~/dotFiles
./scripts/install.sh hermes
sudo nixos-rebuild switch --flake /etc/nixos#hermes
```

After this bump, also double check the `permittedInsecurePackages` entries in `common/base.nix` — they're pinned to exact Emacs version strings from the old nixpkgs, which will likely differ (or no longer be needed at all) on the new one. If a *new* insecure-package error appears with a different version string, add that string instead.

[← back to overview](./overview.md)
