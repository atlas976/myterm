# --- Base ZSH KONFIGURATION ---

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

autoload -Uz compinit
compinit

# Disable Powerlevel10k configuration wizard to ensure it never fires automatically.
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Load Powerlevel10k Theme
source ~/.powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- SECRETS & API KEYS ---
if [[ -f ~/.secrets ]]; then
  source ~/.secrets
fi

# --- FZF (Fuzzy Finder) ---
# Enable fzf keybindings and auto-completion
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh)"
fi