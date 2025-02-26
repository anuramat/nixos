local wezterm = require('wezterm')
local config = wezterm.config_builder()

config.font = wezterm.font('Hack Nerd Font')
config.font_size = 13
config.front_end = 'WebGpu' -- <https://github.com/wezterm/wezterm/issues/5990>
-- config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

return config
