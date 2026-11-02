local M = {}

function M.setup()
  require('base16-colorscheme').setup {
    base00 = '#1e1e2e',
    base01 = '#313244',
    base02 = '#3a3b50',
    base03 = '#6c7086',
    base04 = '#a6adc8',
    base05 = '#cdd6f4',
    base06 = '#cdd6f4',
    base07 = '#cdd6f4',
    base08 = '#f38ba8',
    base09 = '#89dceb',
    base0A = '#89b4fa',
    base0B = '#74c7ec',
    base0C = '#92dfed',
    base0D = '#8fd2f0',
    base0E = '#85b1fa',
    base0F = '#bb1040',
  }
end

local signal = vim.uv.new_signal()
signal:start('sigusr1', vim.schedule_wrap(function()
  package.loaded['matugen'] = nil
  require('matugen').setup()
end))

return M
