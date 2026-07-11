local failures = {}
local configured_servers = {}
local enabled_servers = {}
local mason_lspconfig_options = nil

local function check(condition, message)
  if not condition then
    table.insert(failures, message)
  end
end

package.preload['blink.cmp'] = function()
  return {
    get_lsp_capabilities = function()
      return {
        textDocument = {
          completion = {
            completionItem = {
              snippetSupport = true,
            },
          },
        },
      }
    end,
  }
end

package.preload['mason-tool-installer'] = function()
  return {
    setup = function() end,
  }
end

package.preload['mason-lspconfig'] = function()
  return {
    setup = function(options)
      mason_lspconfig_options = options
    end,
  }
end

vim.lsp.config = function(name, config)
  configured_servers[name] = config
end

vim.lsp.enable = function(servers)
  for _, server in ipairs(servers) do
    enabled_servers[server] = true
  end
end

local root_dir = assert(os.getenv 'REPO_DIR', 'REPO_DIR must be set')
local specification = dofile(root_dir .. '/nvim/lua/myterm/plugins/lsp.lua')
specification.config()

for _, server in ipairs { 'clangd', 'pyright', 'ts_ls', 'texlab', 'lua_ls' } do
  check(configured_servers[server] ~= nil, server .. ' should be configured through vim.lsp.config')
  check(enabled_servers[server] == true, server .. ' should be enabled through vim.lsp.enable')
end

check(
  configured_servers.clangd
    and configured_servers.clangd.capabilities
    and configured_servers.clangd.capabilities.textDocument.completion.completionItem.snippetSupport == true,
  'Blink completion capabilities should be applied to each server'
)
check(
  configured_servers.texlab
    and configured_servers.texlab.settings
    and configured_servers.texlab.settings.texlab.chktex.onEdit == true,
  'Texlab settings should be preserved'
)
check(
  configured_servers.lua_ls
    and configured_servers.lua_ls.settings
    and configured_servers.lua_ls.settings.Lua.format.enable == false,
  'Lua language server settings should be preserved'
)
check(
  mason_lspconfig_options and mason_lspconfig_options.automatic_enable == false,
  'mason-lspconfig automatic enable should be disabled to avoid default configs overriding custom configs'
)
check(
  not (mason_lspconfig_options and mason_lspconfig_options.handlers),
  'legacy mason-lspconfig handlers should not be used'
)

if #failures > 0 then
  for _, failure in ipairs(failures) do
    io.stderr:write('FAIL: ' .. failure .. '\n')
  end
  vim.cmd 'cquit 1'
end

print 'Neovim LSP configuration test passed'
vim.cmd 'qa!'
