return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  keys = {
    { '\\', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle file tree' },
  },
  opts = {
    disable_netrw = true,
    hijack_netrw = true,
    view = {
      width = 32,
      side = 'left',
    },
    renderer = {
      group_empty = true,
      highlight_git = true,
      icons = {
        show = {
          file = vim.g.have_nerd_font,
          folder = vim.g.have_nerd_font,
          folder_arrow = vim.g.have_nerd_font,
          git = true,
        },
      },
    },
    filters = {
      dotfiles = false,
    },
    git = {
      enable = true,
      ignore = false,
    },
    actions = {
      open_file = {
        quit_on_open = false,
        resize_window = true,
      },
    },
  },
}
