return {
  'ellisonleao/gruvbox.nvim',
  priority = 1000,
  config = function()
    require('gruvbox').setup {
      styles = {
        comments = { italic = false },
      },
    }

    vim.o.background = 'dark'
    vim.cmd.colorscheme 'gruvbox'
  end,
}
