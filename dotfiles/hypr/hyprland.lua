-- Docs: https://wiki.hypr.land/Configuring/Start/

hl.monitor({ output = "eDP-1", disabled = true })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })
-- janus-vm. Wildcard outputs are ignored by the Lua API, and without a
-- rule Hyprland picks scale 2 here.
hl.monitor({ output = "Virtual-1", mode = "preferred", position = "auto", scale = 1 })

---- MY PROGRAMS ----

mainMod    = "SUPER"
terminal   = "kitty"
menu       = "rofi -show drun"
fileManager = "thunar"
browser    = "brave"


---- AUTOSTART ----

-- hl.exec_cmd() runs immediately, so autostart goes in hyprland.start.

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("swayosd-server")
    -- --indicator: waybar's tray only shows StatusNotifierItem icons
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")

    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh")
end)

---- ENVIRONMENT VARIABLES ----

-- Posy only ships 32/48/64/96/128 px; other sizes get blurry.
hl.env("XCURSOR_THEME", "Posy_Cursor")
hl.env("XCURSOR_SIZE", "32")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

---- INPUT ----

hl.config({
    input = {
        kb_layout = "us,latam",
        follow_mouse = 1,
        sensitivity = 0.5,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
        },
    },
})

---- LOOK AND FEEL ----

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 0,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            vibrancy = 0.2,
        },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
        },
    },
    animations = {
        enabled = true,
    },
})

hl.curve("easeOut", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default" })

-- LAYOUT
hl.config({
    dwindle = { preserve_split = true },
})
hl.config({
    master = { new_status = "master" },
})

-- MISC
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

---- SPLIT-OUT FILES ----

require("keybinds")
require("rules")