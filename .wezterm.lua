-- ~/.wezterm.lua

local wezterm = require 'wezterm'

return {
  font = wezterm.font("MesloLGS Nerd Font Propo"),
  font_size = 13.0,

  enable_tab_bar = false,
  use_fancy_tab_bar = false,
  -- hide_tab_bar_if_only_one_tab = true,
  enable_scroll_bar = true,
  scrollback_lines = 100000,
  -- cursor_blink_rate = 800,
  default_cursor_style = 'SteadyBlock',


  window_padding = {left = 2, right = 10, top = 1, bottom = 1,},
  keys = {
    {key="UpArrow", mods="CTRL|SHIFT", action=wezterm.action.ScrollByLine(-1)},
    {key="DownArrow", mods="CTRL|SHIFT", action=wezterm.action.ScrollByLine(1)},
    {key="PageUp", mods="CTRL|SHIFT", action=wezterm.action.ScrollByPage(-1)},
    {key="PageDown", mods="CTRL|SHIFT", action=wezterm.action.ScrollByPage(1)},
  },
}
