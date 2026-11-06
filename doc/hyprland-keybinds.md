# Hyprland keyboard shortcuts

Pulled directly from the [43PR/dotfiles](https://github.com/43PR/dotfiles) `hypr/keybinds.conf`. `Super` is the Windows/Cmd key (`$mod`).

## Launch apps
| Shortcut | Action |
|---|---|
| `Super + T` | Open terminal (kitty) |
| `Super + D` | App launcher (rofi) |
| `Super + E` | File manager (Dolphin) |
| `Super + B` | Browser (Firefox) |

## Controllers
| Shortcut | Action |
|---|---|
| `Super + N` | WiFi picker (rofi dmenu — `hypr/scripts/wifi-menu.sh`) |
| `Super + Shift + N` | Full network settings (`nm-connection-editor`) |
| `Super + A` | Audio mixer (`pavucontrol`) |
| `Super + Shift + B` | Bluetooth manager (`blueman-manager`) |

## Window management
| Shortcut | Action |
|---|---|
| `Super + Q` | Close active window |
| `Super + F` | Toggle fullscreen |
| `Super + Space` | Toggle floating |
| `Super + ←/↓/↑/→` | Move focus left/down/up/right |
| `Super + Shift + ←/↓/↑/→` | Move window left/down/up/right |
| `Super + Ctrl + ←/↓/↑/→` | Resize window (hold to repeat) |
| `Super` + drag (mouse button 1) | Move window |
| `Super` + drag (mouse button 2) | Resize window |

## Workspaces
| Shortcut | Action |
|---|---|
| `Super + 1-9, 0` | Switch to workspace 1–10 |
| `Super + Shift + 1-9, 0` | Move active window to workspace 1–10 |

Workspace keys are bound to the physical number row, so on AZERTY press the `& é " ' ( - è _ ç à` keys without Shift.

## System / session
| Shortcut | Action |
|---|---|
| `Super + L` | Lock screen (hyprlock; swaylock inside VirtualBox) |
| `Super + Escape` | Logout menu (wlogout) |
| `Super + Shift + E` | Exit Hyprland session |
| `Super + W` | Wallpaper picker (quickshell) |
| `Super + Shift + W` | Toggle waybar on/off |
| `Super + Z` | Cycle keyboard layout |
| `Super + V` | Clipboard history picker |

## Screenshots
| Shortcut | Action |
|---|---|
| `Super + Delete` | Full screenshot → `~/Pictures/` |
| `Delete` | Region screenshot (drag-select) → `~/Pictures/` |

## Media keys
No modifier — the actual hardware keys.

| Key | Action |
|---|---|
| Volume Up / Down | ±5% volume |
| Mute | Toggle mute |
| Mic mute | Toggle microphone mute |
| Brightness Up / Down | ±5% backlight (via `brightnessctl`) |
| Play/Pause, Next, Previous | Media control (via `playerctl`) |

## Waybar clicks
| Module | Click | Right-click | Scroll |
|---|---|---|---|
| Workspaces | Switch to it | — | Next / previous workspace |
| Network | WiFi picker | `nm-connection-editor` | — |
| Bluetooth | `blueman-manager` | — | — |
| Volume | `pavucontrol` | Toggle mute | ±5% volume |
| Power | `wlogout` | — | — |

## Note on browser / file manager
`dotfiles/hypr/hyprland.lua` still says `brave` and `thunar` (inherited from upstream); `scripts/post-install.sh` rewrites them to `firefox` and `dolphin` when it deploys the config, which is what the tables above reflect.
