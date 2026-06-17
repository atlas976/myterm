local config_dir = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand '<sfile>:p'), ':h')

package.path = table.concat({
  config_dir .. '/lua/?.lua',
  config_dir .. '/lua/?/init.lua',
  package.path,
}, ';')

require 'myterm.options'
require 'myterm.keymaps'
require 'myterm.autocmds'
require 'myterm.lazy'

-- vim: ts=2 sts=2 sw=2 et
