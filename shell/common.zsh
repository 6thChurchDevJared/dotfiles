# ---------------------------------------------------------------------------
# Shared zsh config. Identical on every machine.
# Machine-specific things (Python toolchain, container runtime, work paths)
# belong in ~/.zshrc.local, NOT here.
# ---------------------------------------------------------------------------

# Keep $PATH/$path free of duplicates (first occurrence wins). Without this,
# nested shells and `exec zsh` re-prepend bin/shims and ~/.local/bin every
# time, growing PATH and slowing command lookup.
typeset -U path PATH fpath
path=( $path )

# --- Plugins ---------------------------------------------------------------
# zsh-syntax-highlighting is deliberately NOT sourced here: it wraps the ZLE
# widgets and must be last, after ~/.zshrc.local. The loader does it.
[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] &&
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# --- Completion ------------------------------------------------------------
# Case-insensitive: lowercase input matches uppercase too.
# Custom completion functions (uv/uvx, etc.) must be on fpath before compinit.
fpath=(~/.zsh/completions $fpath)
# Run the slow security audit only when the dump is >24h old; otherwise load
# the cached dump with -C (skips compaudit's stat-every-fpath-file pass).
# NOTE: glob qualifiers do NOT expand inside [[ ]], so the old
# `[[ -n ~/.zcompdump(#qN.mh+24) ]]` form was a non-empty literal string and
# always took the slow branch. An array assignment does glob, so this works.
autoload -Uz compinit
_zdump=( ${ZDOTDIR:-$HOME}/.zcompdump(N.mh+24) )
if (( $#_zdump )); then
  compinit          # dump is stale: full audit + rewrite
else
  compinit -C       # dump is fresh: load it, skip compaudit
fi
unset _zdump
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- PATH ------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# pnpm. $HOME rather than a hardcoded username so this file is portable.
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- fzf -------------------------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- Rust/oxide replacements ----------------------------------------------
# All installed via Homebrew (see Brewfile), not cargo.
alias ls="eza --icons"
alias ll="eza -la --icons"
alias cat="bat --plain"
alias find="fd"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
alias zi="z --interactive"

# --- git -------------------------------------------------------------------
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline --graph --decorate"

# --- navigation ------------------------------------------------------------
setopt AUTO_CD              # type a directory name without cd to navigate to it
alias ..="cd .."
alias ...="cd ../.."

# --- history ---------------------------------------------------------------
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE    # commands starting with a space won't be saved
setopt SHARE_HISTORY        # share history across terminal sessions

# --- prompt ----------------------------------------------------------------
# The Mac Mini drives the prompt: config/starship.toml is its 141-line "glass"
# theme. Guarded so a machine without starship installed still gets a usable
# prompt rather than an error on every shell.
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
else
  PROMPT='%~ # '   # brew install starship to get the real one
fi

# --- tools that need shell init -------------------------------------------
# Present on the Mac Mini, absent on the MacBook Pro. Each is guarded, so this
# block is a no-op on a machine that does not have the tool.
command -v mise  >/dev/null && eval "$(mise activate zsh)"      # runtime versions
command -v atuin >/dev/null && eval "$(atuin init zsh)"         # shell history
command -v broot >/dev/null && [ -f ~/.config/broot/launcher/bash/br ] &&
  source ~/.config/broot/launcher/bash/br

# --- Deep Work toggles -----------------------------------------------------
# `dw` = calm environment (dock hidden, desktop cleared, Ghostty up, + Focus/Slack
# if the "Deep Work On" Shortcut exists). `dwoff` restores.
alias dw='~/.deepwork/on.sh'
alias dwoff='~/.deepwork/off.sh'
alias deepwork='~/.deepwork/on.sh'
alias surface='~/.deepwork/off.sh'
