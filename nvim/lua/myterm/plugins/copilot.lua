return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      hide_during_completion = true,
      debounce = 75,
      keymap = {
        accept = '<C-l>',
        accept_word = false,
        accept_line = false,
        next = false,
        prev = false,
        dismiss = '<C-]>',
      },
    },
    panel = {
      enabled = true,
      auto_refresh = true,
      keymap = {
        open = '<M-CR>',
      },
    },
    filetypes = {
      gitcommit = false,
      markdown = true,
      yaml = true,
    },
  },
}
