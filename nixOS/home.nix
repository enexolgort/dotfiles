{ config, pkgs, lib, vars, ... }:

{
  home.username = vars.username;
  home.homeDirectory = "/home/${vars.username}";
  home.stateVersion = "24.11";

  # Doom manages itself (git clone + doom sync) rather than being nixified.
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };

  # Socket-activated daemon. Needs `loginctl enable-linger` to outlive the session.
  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = true;
    socketActivation.enable = true;
  };

  # Tools Doom expects on PATH.
  home.packages = with pkgs; [
    git
    ripgrep
    fd
    coreutils
    imagemagick
    sqlite            # org-roam
    fontconfig
    nerd-fonts.jetbrains-mono
    gnutls
    unzip
    hyfetch            # neowofetch; neofetch was removed in nixos-26.05
  ];

  home.activation.installDoomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DOOM_DIR="$HOME/.config/emacs"
    DOOM_CONF="$HOME/.config/doom"

    if [ ! -d "$DOOM_DIR" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/doomemacs/doomemacs "$DOOM_DIR"
    fi

    if [ ! -d "$DOOM_CONF" ]; then
      $DRY_RUN_CMD "$DOOM_DIR/bin/doom" install --no-env -! \
        || echo "doom install failed - run 'doom install' manually as the ${vars.username} user"
    fi
  '';

  home.sessionPath = [ "$HOME/.config/emacs/bin" ];

  # Read by neowofetch.
  xdg.configFile."neofetch/config.conf".text = ''
    print_info() {
        info title
        info underline
        info "OS" distro
        info "Host" model
        info "Kernel" kernel
        info "Uptime" uptime
        info "Packages" packages
        info "Shell" shell
        info "Terminal" term
        info "CPU" cpu
        info "GPU" gpu
        info "Memory" memory
        info "Disk" disk
        info "Local IP" local_ip
        info "Locale" locale
        info cols
    }

    ascii_distro="auto"
    ascii_colors=(distro)
    ascii_bold="on"

    bold="on"
    underline_enabled="on"
    underline_char="-"
    separator=" ->"

    color_blocks="on"
    block_range=(0 15)
    block_width=3
    block_height=1
    col_offset="auto"

    memory_percent="on"
    memory_unit="gib"

    disk_show=("/")
    disk_subtitle="mount"
    disk_percent="on"

    speed_type="bios_limit"
    cpu_brand="on"
    cpu_speed="on"
    cpu_cores="logical"
    cpu_temp="off"

    gpu_brand="on"
    gpu_type="all"

    image_backend="ascii"
  '';

  programs.bash = {
    enable = true;

    initExtra = ''
      # Interactive shells only, so scp/rsync/git-over-ssh stay clean.
      if [[ $- == *i* ]]; then
        neowofetch
      fi

      # move/copy/rename --source <path> --destination <path>
      _parse_source_dest() {
        local fn_name="$1"; shift
        __src=""
        __dst=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --source) __src="$2"; shift 2 ;;
            --destination) __dst="$2"; shift 2 ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
          esac
        done
        if [[ -z "$__src" || -z "$__dst" ]]; then
          echo "Usage: $fn_name --source <path> --destination <path>" >&2
          return 1
        fi
      }

      move() {
        _parse_source_dest move "$@" || return 1
        mv -- "$__src" "$__dst"
      }

      copy() {
        _parse_source_dest copy "$@" || return 1
        cp -r -- "$__src" "$__dst"
      }

      rename() {
        _parse_source_dest rename "$@" || return 1
        mv -- "$__src" "$__dst"
      }

      # No args: terminal Emacs. Otherwise: the Doom CLI.
      doom() {
        if [ $# -eq 0 ]; then
          emacs -nw
        else
          "$HOME/.config/emacs/bin/doom" "$@"
        fi
      }

      # nixos-rebuild picks the host from the hostname.
      alias rebuild='sudo nixos-rebuild switch --flake /etc/nixos'

      # Pull, install into /etc/nixos, rebuild, post-install.
      update-server() {
        local repo="$HOME/dotFiles"
        if [ ! -d "$repo" ]; then
          echo "Repo not found at $repo — edit the 'update-server' function in home.nix if it lives elsewhere." >&2
          return 1
        fi
        (
          set -e
          cd "$repo"
          git pull
          ./scripts/install.sh
          sudo nixos-rebuild switch --flake /etc/nixos
          ./scripts/post-install.sh
        )
      }

      # backup/restore --nixVars: copy vars.nix to/from ~/backup.
      backup() {
        case "$1" in
          --nixVars)
            mkdir -p "$HOME/backup"
            if [ ! -f "$HOME/dotFiles/nixOS/vars.nix" ]; then
              echo "Not found: $HOME/dotFiles/nixOS/vars.nix" >&2
              return 1
            fi
            cp "$HOME/dotFiles/nixOS/vars.nix" "$HOME/backup/vars.nix" \
              && echo "Backed up vars.nix -> $HOME/backup/vars.nix"
            ;;
          *)
            echo "Usage: backup --nixVars" >&2
            return 1
            ;;
        esac
      }

      restore() {
        case "$1" in
          --nixVars)
            if [ ! -f "$HOME/backup/vars.nix" ]; then
              echo "No backup found at $HOME/backup/vars.nix — run 'backup --nixVars' first" >&2
              return 1
            fi
            cp "$HOME/backup/vars.nix" "$HOME/dotFiles/nixOS/vars.nix" \
              && echo "Restored vars.nix -> $HOME/dotFiles/nixOS/vars.nix"
            ;;
          *)
            echo "Usage: restore --nixVars" >&2
            return 1
            ;;
        esac
      }
    '';
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = vars.username;
      email = vars.gitEmail;
    };
  };
}
