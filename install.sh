#!/usr/bin/env bash
# Link this repo's configs into $HOME. Idempotent, and it never destroys
# anything: an existing real file is moved to <name>.bak.<timestamp> first.
#
#   ./install.sh              link everything, then report
#   ./install.sh --dry-run    show what would happen, touch nothing
#   ./install.sh --brew       also run brew bundle for this machine
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
DRY=0; BREW=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --brew)    BREW=1 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then say "would: $*"; else "$@"; fi; }

link() {  # link <repo-relative source> <absolute target>
  local src="$DOTFILES/$1" dst="$2"
  [ -e "$src" ] || { say "SKIP  $1 (not in repo)"; return; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "ok    $dst"
    return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    say "backup $dst -> $dst.bak.$STAMP"
    run mv "$dst" "$dst.bak.$STAMP"
  fi
  run ln -s "$src" "$dst"
  say "link  $dst -> $1"
}

seed() {  # seed <repo example> <absolute target>   (copy, never overwrite)
  local src="$DOTFILES/$1" dst="$2"
  if [ -e "$dst" ]; then say "keep  $dst (already exists)"; return; fi
  run cp "$src" "$dst"
  say "seed  $dst (edit it, it is not tracked)"
}

echo "dotfiles: $DOTFILES"
[ "$DRY" = 1 ] && echo "DRY RUN — nothing will be changed"

echo; echo "shell:"
link shell/zshrc            "$HOME/.zshrc"
link shell/zshenv           "$HOME/.zshenv"
link shell/zprofile         "$HOME/.zprofile"

echo; echo "git:"
link git/gitconfig          "$HOME/.gitconfig"
link git/ignore             "$HOME/.config/git/ignore"

echo; echo "apps:"
link config/ghostty/config  "$HOME/.config/ghostty/config"
link config/zed/settings.json "$HOME/.config/zed/settings.json"
link config/zellij/config.kdl "$HOME/.config/zellij/config.kdl"
link config/starship.toml   "$HOME/.config/starship.toml"
link config/nvim            "$HOME/.config/nvim"

echo; echo "scripts:"
run mkdir -p "$HOME/.deepwork"
for s in on.sh off.sh; do link "bin/$s" "$HOME/.deepwork/$s"; done

echo; echo "machine-local (not tracked):"
case "$(scutil --get ComputerName 2>/dev/null || hostname)" in
  *[Mm]ini*) seed local/zshrc.local.mini.example    "$HOME/.zshrc.local" ;;
  *)         seed local/zshrc.local.macbook.example "$HOME/.zshrc.local" ;;
esac
seed local/gitconfig.local.example "$HOME/.gitconfig.local"

echo; echo "zsh plugins:"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ -d "$HOME/.zsh/$p" ]; then say "ok    ~/.zsh/$p"
  else
    say "clone ~/.zsh/$p"
    run git clone -q --depth 1 "https://github.com/zsh-users/$p" "$HOME/.zsh/$p"
  fi
done
run mkdir -p "$HOME/.zsh/completions"

if [ "$BREW" = 1 ]; then
  echo; echo "brew:"
  run brew bundle --file="$DOTFILES/Brewfile"
  case "$(scutil --get ComputerName 2>/dev/null || hostname)" in
    *[Mm]ini*) [ -s "$DOTFILES/Brewfile.mini" ] && run brew bundle --file="$DOTFILES/Brewfile.mini" ;;
    *)         run brew bundle --file="$DOTFILES/Brewfile.macbook" ;;
  esac
fi

echo
echo "done. Open a new shell, or: exec zsh"
echo "Edit ~/.zshrc.local for anything specific to this machine."
