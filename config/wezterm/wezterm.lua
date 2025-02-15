local wezterm = require('wezterm')
local config = wezterm.config_builder()

config.font = wezterm.font('Hack Nerd Font')
config.font_size = 13
config.front_end = 'WebGpu' -- <https://github.com/wezterm/wezterm/issues/5990>

return config
