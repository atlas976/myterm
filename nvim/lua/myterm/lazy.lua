local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }

  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { 'NMAC427/guess-indent.nvim', opts = {} },
  require 'myterm.plugins.git',
  require 'myterm.plugins.which-key',
  require 'myterm.plugins.nvim-tree',
  require 'myterm.plugins.telescope',
  require 'myterm.plugins.lsp',
  require 'myterm.plugins.formatting',
  require 'myterm.plugins.completion',
  require 'myterm.plugins.copilot',
  require 'myterm.plugins.colorscheme',
  require 'myterm.plugins.todo-comments',
  require 'myterm.plugins.mini',
  require 'myterm.plugins.treesitter',
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
