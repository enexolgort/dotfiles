# Dotfiles Review — Gaps, Drift, Missing Files (Nov 16, 2026)

**Repository:** `~/dotfiles` | **System:** Mixed bare-metal NixOS homelab + WSL laptop client  
**Goal:** Deploy multi-machine homelab (jellyfin, forgejo, tailscale ssh, docker, couchdb obsidian, sftp, n8n, ai) to real machines or WSL, then provide local desktop (janus host) for SSH/browser access.

---

## Critical: These Files Are Missing and Will Break install.sh

### 1. `nixOS/vars.nix` does not exist (install.sh fails)
- **Why needed:** install.sh clones project repos to `/data/projects` and needs defaults + per-host toggles from this file.  
- **Current state:** Only host-specific `hosts/<name>/vars.nix` configs exist; a root `nixOS/vars.nix` with default SSH keys, git email, shared secrets is missing.
- **Impact:** install.sh will error on "Not found: /home/enexolgort/dotFiles/nixOS/vars.nix" or write empty defaults causing host config drift.

### 2. `nixOS/home-desktop.nix` exists but is incomplete  
- **Purpose:** home-manager module for hosts with `desktopEnable = true` (janus).
- **Current content:** Waybar enabled, basic cursor settings — missing Hyprland integration, proper hyprlock config merge, notifications (mako), bluetooth manager, terminal emulator preferences.
- **Why incomplete:** Initial stub written but needs proper desktop compose (hyprland + wlogout integration, power menu scripts included in sessions).

### 3. `wsl-configuration.nix` missing entirely  
- Referenced by flake.nix on line 57 for WSL targets; currently non-existent causing build failure when building janus-vm or any WSL host target.
- **Needed:** Base WSL package set, XWayland enablement, common tools (zsh/fzf/ripgrep), user account setup for non-NixOS laptop environment.

### 4. `treefmt.nix` missing  
- Flake exports formatter checks at lines 72–80 but treefmt config file is absent; the build target fails silently or errors on CI.
- **Need:** Formatter rules (nixpkgs-checks, shellcheck for scripts, etc.) plus lint targets.

---

## Configuration Drift / Inconsistencies

### 1. Bash profile symlinks point to store paths, not real files
```bash
/home/enexolgort/.bash_profile -> /nix/store/ba8rdggb917inc577f6bxixivy53mpsf-home-manager-files/.bash_profile
/home/enexolgort/.profile -> /nix/store/ba8rdggb917inc577f6bxixivy53mpsf-home-manager-files/.profile
```
These link to a home-manager build in `/nix/store` but the actual config lives under `~/dotfiles`. On your current laptop:
- `~/.config/nix/home-manager/home.nix` doesn't exist (you said "Not using home-manager nix file").
**Problem:** Your dotfiles repo uses NixOS profiles intended for real machines (or WSL), but you're running them locally in bare shell. This creates a split:
- Remote servers (mnemosyne, hermes) use full NixOS configs with flakes.
- Local laptop runs plain ~/.bashrc, no home-manager, so `home.nix` imports never execute here.

**Resolution:** Either migrate the local machine to home-manager/Nix (relink profiles), or adapt install.sh/scripts to work in bare metal for this client machine without NixOS deployment.

### 2. janus/vars.nix has placeholder GPU bus IDs
```nix
nvidiaPrime = {
  intelBusId = "PCI:0:2:0";      # ← needs lspci output
  nvidiaBusId = "PCI:1:0:0";     # ← comment says "use amdgpuBusId for AMD CPU"
};
```
janus host sets `nvidiaEnable = true`, but PCI IDs are placeholders. If this laptop has AMD GPU, you should use `amdgpuBusId` in vars.nix and disable nvidiaEnable.

**Action:** Run `lspci | grep -E "VGA|3D"` on janus laptop → update values or swap to amdgpu config. Currently wrong for any deployment.

### 3. first-boot-setup.md references services disabled on janus
- doc/first-boot-setup.md lists Tailscale, Jellyfin, Obsidian sync setup as one-time tasks post-install.sh.
- But janus host (desktop client) disables jellyfinEnable, obsidianEnable, gitServerEnable per vars.nix.
**Confusion:** first-boot docs target server-style setup, but janus is just SSH/browser access — should these steps live in a different doc or be skipped for desktop-only builds?

### 4. check-remote.sh usage mismatch
- README lines 29–33 show running `./scripts/check-remote.sh --host mnemosyne` from "any client device on your tailnet".
- On the local laptop (janus), you're NOT deploying NixOS profiles here; instead, use this script to SSH into remote homelab machines for testing.
**Clarity gap:** first-boot-setup.md implies run all steps locally, but janus isn't deployed via flake — it's a shell client running scripts against remote servers.

### 5. install.sh logic assumes target /etc/nixos exists
- Lines in home.nix: `nixos-rebuild switch --flake /etc/nixos` for mnemosyne/hermes/etc.
- But you'd run install.sh on janus laptop where `/etc/nixos` doesn't exist locally (only remotely).
**Question:** Does install.sh copy projectRepos to remote server's /data/projects via SSH, or does it fail because flake targets don't match current host?

### 6. Secrets file not present
- dotfiles/doc/secrets.md references sops-nix for encrypted secrets but no actual secrets.txt exists.
- sshAuthorizedKeys in defaults.nix contains just "sftp-laptop" entry; real key material missing from secrets store.

---

## Documentation Gaps

1. **doc/overview.md:** Should explain the split between NixOS servers vs local laptop client usage — currently focuses on multi-NixOS deployment only.
2. **doc/deploy-wsl.md:** References WSL installs but no real wsl-configuration.nix existed until just now; guide needs updating once proper defaults are written.
3. **hyprland-keybinds.md:** Pulls keybinds from 43PR's config; needs integration with your own dotfiles scripts (now-playing, wallpaper, bluetooth-menu). Not referenced in main docs despite being functional.

---

## Action Items (Prioritized)

### Must-do before install.sh will work:
- [ ] Create `nixOS/vars.nix` with defaults SSH keys, gitEmail placeholders, service flags for all hosts
- [ ] Implement `treefmt.nix` with at least nix/lua/shellcheck formatters and run targets
- [ ] Fill janus/vars.nix GPU bus IDs (lspci output) or switch to amdgpuBusId + disable nvidiaEnable
- [ ] Flesh out home-desktop.nix with proper Hyprland+waybar+mako power menu integration
- [ ] Update wsl-configuration.nix with actual WSL setup and package set

### Review for deployment strategy:
- [ ] Decide if janus laptop runs NixOS profiles locally or only SSHs remotes; reconcile /etc/nixos presence vs bare-metal client usage
- [ ] Split doc/first-boot-setup.md into two docs: server-host setup vs desktop-first-boot (janus)
- [ ] Add secrets.txt with proper sops-encrypted keys to secure homelab deployments

---

## Summary

Repository has **4 critical missing files**, **6 config drift issues**, and **3 documentation gaps** that will cause install.sh failures or deployment inconsistencies. The core NixOS build system (flake.nix/module paths) assumes these defaults exist but they're not on any local machine except a real homelab host. The laptop janus hosts hybrid usage: some services disabled, desktop stack enabled with GPU placeholders needing lspci fill-in.

**Next step:** Generate the missing config files once deployment strategy is clear (local bash client vs remote NixOS profiles).
