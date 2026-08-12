# headfull — Hyprland keyboard shortcuts

Pulled directly from the [43PR/dotfiles](https://github.com/43PR/dotfiles) `hypr/keybinds.conf`. `Super` is the Windows/Cmd key (`$mod`).

## Launch apps
| Shortcut | Action |
|---|---|
| `Super + T` | Open terminal (kitty) |
| `Super + D` | App launcher (rofi) |
| `Super + E` | File manager (thunar) |
| `Super + B` | Browser |

## Window management
| Shortcut | Action |
|---|---|
| `Super + Q` | Close active window |
| `Super + F` | Toggle fullscreen |
| `Super + Space` | Toggle floating |
| `Super + H/J/K/L` | Move focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Move window left/down/up/right |
| `Super + Ctrl + H/J/K/L` | Resize window (left/right/up/down) |
| `Super` + drag (mouse button 1) | Move window |
| `Super` + drag (mouse button 2) | Resize window |

## Workspaces
| Shortcut | Action |
|---|---|
| `Super + 1-9, 0` | Switch to workspace 1–10 |
| `Super + Shift + 1-9, 0` | Move active window to workspace 1–10 |

## System / session
| Shortcut | Action |
|---|---|
| `Super + Tab` | Lock screen (hyprlock) |
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
| Play/Pause, Next, Previous | Media control (via `playerctl`) |

## Known mismatch
`Super + B` launches `brave` literally in the dotfiles' config — but `headfull` installs **Firefox**, not Brave, so this shortcut won't work until `$browser` in `hypr/hyprland.conf` (or a home-manager override) is updated to point at `firefox` instead.
