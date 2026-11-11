-- Docs: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- Rule names must be unique: rules sharing a name merge into one.

local window_opacity = 0.7

-- Ignore client maximize requests (kitty) so new windows tile; Super+F still works.
hl.window_rule({
    name = "no-client-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Layer rules
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.15,
})

-- Opacity for regular apps
hl.window_rule({
    name = "opacity-apps",
    match = {
        class = "^(kitty|herdr-app|xed|thunar|brave-browser|discord|codium|GeForceNOW|obsidian|Spotify|org.pulseaudio.pavucontrol|com.github.johnfactotum.Foliate)$",
    },
    opacity = window_opacity .. " override " .. window_opacity .. " override 1.0 override",
})

-- Calendar popup from the waybar clock: floating, centred under the bar
hl.window_rule({
    name = "calendar-popup",
    match = { class = "^(gsimplecal)$" },
    float = true,
    move = "(monitor_w*0.5-window_w*0.5) 40",
})

-- Float rules
hl.window_rule({
    name = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "float-nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})

hl.window_rule({
    name = "float-blueman-manager",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name = "float-open-file",
    match = { title = "^(Open File)$" },
    float = true,
})

hl.window_rule({
    name = "float-save-file",
    match = { title = "^(Save File)$" },
    float = true,
})