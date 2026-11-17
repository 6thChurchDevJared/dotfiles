#!/usr/bin/env bash
# Link this repo's configs into $HOME. Idempotent, and it never destroys
# anything: an existing real file is moved to <name>.bak.<timestamp> first.
#
#   ./install.sh              link everything, then report
#   ./install.sh --dry-run    show what would happen, touch nothing
#   ./install.sh --packages   also install packages: brew bundle on macOS,
#                             packages/linux.sh on Debian-family Linux
#                             (--brew is the old name, still accepted)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
DRY=0; PKGS=0
OS="$(uname -s)"   # Darwin | Linux
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --packages|--brew) PKGS=1 ;;
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

echo "dotfiles: $DOTFILES ($OS)"
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

# bin/ needs no links: common.zsh puts $DOTFILES/bin on PATH.
if [ "$OS" = Darwin ]; then
  echo; echo "deep work (macOS):"
  run mkdir -p "$HOME/.deepwork"
  for s in on.sh off.sh; do link "deepwork/$s" "$HOME/.deepwork/$s"; done
fi

echo; echo "machine-local (not tracked):"
machine() {  # macbook | mini | linux
  if [ "$OS" = Linux ]; then echo linux; return; fi
  case "$(scutil --get ComputerName 2>/dev/null || hostname)" in
    *[Mm]ini*) echo mini ;;
    *)         echo macbook ;;
  esac
}
seed "local/zshrc.local.$(machine).example" "$HOME/.zshrc.local"
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

if [ "$PKGS" = 1 ]; then
  echo; echo "packages:"
  case "$(machine)" in
    linux)   if [ "$DRY" = 1 ]; then "$DOTFILES/packages/linux.sh" --dry-run
             else "$DOTFILES/packages/linux.sh"; fi ;;
    mini)    run brew bundle --file="$DOTFILES/Brewfile"
             [ -s "$DOTFILES/Brewfile.mini" ] && run brew bundle --file="$DOTFILES/Brewfile.mini" ;;
    macbook) run brew bundle --file="$DOTFILES/Brewfile"
             run brew bundle --file="$DOTFILES/Brewfile.macbook" ;;
  esac
fi

echo
echo "done. Open a new shell, or: exec zsh"
echo "Edit ~/.zshrc.local for anything specific to this machine."

# Linking git/gitconfig replaces whatever identity was in ~/.gitconfig, and the
# seeded ~/.gitconfig.local carries a placeholder. Left unedited, every commit
# on this machine is authored you@example.com and nothing warns you.
if grep -q 'you@example.com' "$HOME/.gitconfig.local" 2>/dev/null; then
  echo
  echo "  !! ~/.gitconfig.local still has the placeholder email."
  echo "  !! Commits on this machine would be authored you@example.com."
  echo "  !! Fix it now:"
  echo "        git config --file ~/.gitconfig.local user.email 'you@real.address'"
fi
