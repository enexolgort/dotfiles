-- ~/.config/hypr/rules.lua
-- Migrated from rules.conf
-- Docs: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- IMPORTANT FIX vs your old file: your old rules.conf had four separate
-- `windowrule { name = float ... }` blocks that all reused the SAME name
-- ("float") and never actually set a float effect. In hyprlang each block
-- was independent so this mostly worked by accident. In the Lua API, named
-- rules with the same name are treated as the same rule and later
-- declarations MERGE INTO / OVERWRITE earlier ones - so reusing "float"
-- four times would leave you with only one (broken, effect-less) rule.
-- Below, each rule gets a unique name and the missing `float = true` is added.

local window_opacity = 0.7

-- Keep new windows tiled: some clients (kitty here) ask to be maximized
-- when they open, so a new window covered the whole workspace instead of
-- splitting it. Ignore client maximize requests; Super+F still works.
-- Verified on janus-vm: 4 kitty windows tiled 632/632/314/312 px wide.
hl.window_rule({
    name = "no-client-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Layer rules (old: layerrule = blur on / ignore_alpha 0.15, match:namespace rofi)
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.15,
})

-- Opacity rule for your regular apps
hl.window_rule({
    name = "opacity-apps",
    match = {
        class = "^(kitty|xed|thunar|brave-browser|discord|codium|GeForceNOW|obsidian|Spotify|org.pulseaudio.pavucontrol|com.github.johnfactotum.Foliate)$",
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

-- Float rules (fixed: unique names + float = true actually set)
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