local M = {}

local uv = vim.uv or vim.loop

local function config_home()
  return os.getenv 'XDG_CONFIG_HOME' or vim.fn.expand '~/.config'
end

local function state_file()
  return table.concat({ config_home(), 'myterm', 'copilot-enabled' }, '/')
end

local function copilot_is_loaded()
  local ok, config = pcall(require, 'lazy.core.config')
  local plugin = ok and config.plugins['copilot.lua']

  return plugin ~= nil and plugin._ ~= nil and plugin._.loaded ~= nil
end

local function copilot_command(command)
  if vim.fn.exists ':Copilot' ~= 2 then
    return false
  end

  pcall(vim.cmd, 'silent! Copilot ' .. command)
  return true
end

function M.is_enabled()
  local stat = uv.fs_stat(state_file())
  return stat ~= nil and stat.type == 'file'
end

function M.enable()
  local ok, lazy = pcall(require, 'lazy')
  if ok then
    pcall(lazy.load, { plugins = { 'copilot.lua' }, wait = true })
  end

  if copilot_command 'enable' then
    return 'Copilot enabled'
  end

  return 'Copilot enabled; plugin is not loaded yet'
end

function M.disable()
  if not copilot_is_loaded() then
    return 'Copilot disabled; plugin is not loaded'
  end

  if copilot_command 'disable' then
    return 'Copilot disabled'
  end

  return 'Copilot disabled; plugin is not loaded'
end

function M.sync_from_state()
  if M.is_enabled() then
    return M.enable()
  end

  return M.disable()
end

function M.toggle()
  local path = state_file()

  if M.is_enabled() then
    os.remove(path)
  else
    vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
    local file = assert(io.open(path, 'w'))
    file:write('enabled\n')
    file:close()
  end

  return M.sync_from_state()
end

function M.setup_commands()
  local actions = {
    enable = function()
      local path = state_file()
      vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
      local file = assert(io.open(path, 'w'))
      file:write('enabled\n')
      file:close()

      return M.sync_from_state()
    end,
    disable = function()
      os.remove(state_file())
      return M.sync_from_state()
    end,
    toggle = M.toggle,
    status = function()
      return 'Copilot is ' .. (M.is_enabled() and 'enabled' or 'disabled')
    end,
  }

  vim.api.nvim_create_user_command('Mycp', function(opts)
    local action = actions[opts.args]

    if not action then
      vim.notify('Usage: mycp enable|disable|toggle|status', vim.log.levels.ERROR)
      return
    end

    vim.notify(action(), vim.log.levels.INFO)
  end, {
    nargs = 1,
    complete = function()
      return { 'enable', 'disable', 'toggle', 'status' }
    end,
  })

  vim.cmd [[
    cnoreabbrev <expr> mycp getcmdtype() ==# ':' && getcmdline() ==# 'mycp' ? 'Mycp' : 'mycp'
  ]]
end

function M.setup()
  M.setup_commands()
end

return M
