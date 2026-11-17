# ---------------------------------------------------------------------------
# Shared zsh config. Identical on every machine, macOS and Linux.
# Machine-specific things (Python toolchain, container runtime, work paths)
# belong in ~/.zshrc.local, NOT here. Branch on the OS, never on a hostname.
# ---------------------------------------------------------------------------

# Keep $PATH/$path free of duplicates (first occurrence wins). Without this,
# nested shells and `exec zsh` re-prepend bin/shims and ~/.local/bin every
# time, growing PATH and slowing command lookup.
typeset -U path PATH fpath
path=( $path )

# --- Vi mode ---------------------------------------------------------------
# First, before anything that binds keys. `bindkey -v` switches the main
# keymap to viins, so bindings fzf/atuin/autosuggestions made earlier into the
# emacs keymap would silently stop working (Ctrl-R is the usual casualty).
bindkey -v
export KEYTIMEOUT=1   # 10ms Esc. The 0.4s default makes Esc feel laggy.

# `v` in normal mode opens the current command line in $EDITOR. Write and
# quit runs it; :cq abandons it.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Readline keys every other prompt (ssh, psql, python REPL) still uses. Not
# vim, but fighting them in one place only is worse. ^? and ^H also fix vi
# mode's default refusal to backspace past where insert mode began.
bindkey -M viins '^A' beginning-of-line '^E' end-of-line \
  '^W' backward-kill-word '^U' backward-kill-line \
  '^?' backward-delete-char '^H' backward-delete-char

# Cursor shows the mode: block in normal, bar in insert.
_vi_cursor() {
  if [[ $KEYMAP == vicmd ]]; then printf '\e[2 q'; else printf '\e[6 q'; fi
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget keymap-select _vi_cursor
add-zle-hook-widget line-init _vi_cursor

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
# ~/.local/bin: uv, and on Linux the tools packages/linux.sh installs from
# GitHub releases. $DOTFILES/bin: your own scripts (see `newscript`), first so
# they are versioned and follow you to every machine.
export PATH="${DOTFILES:-$HOME/Developer/dotfiles}/bin:$HOME/.local/bin:$PATH"

# pnpm, only where it is installed. Its home differs by OS.
if [[ $OSTYPE == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
[ -d "$PNPM_HOME" ] && path=("$PNPM_HOME" $path)

# --- Editor ----------------------------------------------------------------
# nvim everywhere it exists: git commits, `kubectl edit`, `crontab -e`, `fc`,
# and the `v` binding above all open it. Plain vi on a box without it.
if (( $+commands[nvim] )); then
  export EDITOR=nvim VISUAL=nvim
  export MANPAGER='nvim +Man!'   # man pages with vim motions; gO = outline
  alias vi=nvim vim=nvim
else
  export EDITOR=vi VISUAL=vi
fi

# --- Rust/oxide replacements ----------------------------------------------
# macOS: Homebrew (Brewfile). Linux: apt or GitHub releases (packages/linux.sh).
# Every alias is guarded, so a fresh box without the tool keeps the original
# command instead of a broken alias.
# Debian ships bat as `batcat` and fd as `fdfind`. linux.sh symlinks the real
# names into ~/.local/bin; these cover a box where it has not run yet.
(( $+commands[bat] )) || { (( $+commands[batcat] )) && alias bat=batcat; }
(( $+commands[fd] ))  || { (( $+commands[fdfind] )) && alias fd=fdfind; }

if (( $+commands[eza] )); then
  # --icons=auto, NOT bare --icons: bare --icons takes an optional value, so
  # `ls <path>` parsed the path as that value and errored out.
  alias ls='eza --icons=auto' ll='eza -la --icons=auto'
else
  alias ll='ls -la'
fi
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat --plain'
(( $+commands[fd]  || $+commands[fdfind] )) && alias find='fd'
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)" && alias zi='z --interactive'

# --- fzf -------------------------------------------------------------------
# After `bindkey -v`, so Ctrl-R / Ctrl-T / Alt-C land in the vi keymaps.
# `fzf --zsh` needs fzf >= 0.48; older Debian packages ship the script instead.
if (( $+commands[fzf] )); then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  fi
fi

# --- git -------------------------------------------------------------------
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline --graph --decorate"
(( $+commands[lazygit] )) && alias lg='lazygit'

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
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
else
  PROMPT='%m:%~ %# '   # hostname, so an ssh session is obvious
fi

# --- tools that need shell init -------------------------------------------
# Present on the Mac Mini, absent on the MacBook Pro. Each is guarded, so this
# block is a no-op on a machine that does not have the tool. atuin rebinds
# Ctrl-R, and wins over fzf because it comes later.
(( $+commands[mise] ))  && eval "$(mise activate zsh)"      # runtime versions
(( $+commands[atuin] )) && eval "$(atuin init zsh)"         # shell history
(( $+commands[broot] )) && [ -f ~/.config/broot/launcher/bash/br ] &&
  source ~/.config/broot/launcher/bash/br

# --- Deep Work toggles (macOS only) ----------------------------------------
# `dw` = calm environment (dock hidden, desktop cleared, Ghostty up, + Focus/Slack
# if the "Deep Work On" Shortcut exists). `dwoff` restores.
if [[ $OSTYPE == darwin* ]]; then
  alias dw='~/.deepwork/on.sh'
  alias dwoff='~/.deepwork/off.sh'
  alias deepwork='~/.deepwork/on.sh'
  alias surface='~/.deepwork/off.sh'
fi
