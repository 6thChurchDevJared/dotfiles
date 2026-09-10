#!/usr/bin/env bash
# Pull THIS machine's live configs into the repo, so two machines can be
# reconciled with a real diff instead of by memory.
#
#   ./collect.sh          copy live configs over the repo copies, then `git diff`
#   ./collect.sh --dump   print one pasteable bundle to stdout and change nothing
#
# Intended flow (Mac Mini is the source of truth for shared config):
#   on the Mini:  git clone <repo> && cd dotfiles && git checkout -b mini
#                 ./collect.sh && git add -A && git commit -m "mini: as-installed"
#   then:         merge mini into main, Mini winning on the shared files
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-copy}"

# repo path <- live path
PAIRS=(
  "config/ghostty/config|$HOME/.config/ghostty/config"
  "config/zed/settings.json|$HOME/.config/zed/settings.json"
  "config/zellij/config.kdl|$HOME/.config/zellij/config.kdl"
  "config/starship.toml|$HOME/.config/starship.toml"
  "git/ignore|$HOME/.config/git/ignore"
)

if [ "$MODE" = "--dump" ]; then
  echo "### machine: $(scutil --get ComputerName 2>/dev/null || hostname)"
  echo "### macos:   $(sw_vers -productVersion)  arch: $(uname -m)"
  echo "### date:    $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "### brew leaves"; brew leaves 2>/dev/null || true
  echo; echo "### brew casks"; brew list --cask 2>/dev/null || true
  echo; echo "### cargo bin"; ls ~/.cargo/bin 2>/dev/null || true
  echo; echo "### zed extensions"; ls "$HOME/Library/Application Support/Zed/extensions/installed" 2>/dev/null || true
  for p in "${PAIRS[@]}"; do
    live="${p#*|}"
    echo; echo "### FILE ${live/#$HOME/\~}"
    [ -f "$live" ] && cat "$live" || echo "(missing)"
  done
  for f in "$HOME/.zshrc" "$HOME/.zshrc.local" "$HOME/.zprofile" "$HOME/.zshenv"; do
    echo; echo "### FILE ${f/#$HOME/\~}"
    [ -f "$f" ] && cat "$f" || echo "(missing)"
  done
  echo; echo "### FILE ~/.config/nvim (file list only)"
  find "$HOME/.config/nvim" -type f -not -path '*/.git/*' 2>/dev/null | sed "s|$HOME|~|" || true
  exit 0
fi

for p in "${PAIRS[@]}"; do
  repo="$DOTFILES/${p%%|*}"; live="${p#*|}"
  if [ -f "$live" ] && [ ! -L "$live" ]; then
    mkdir -p "$(dirname "$repo")"; cp "$live" "$repo"; echo "  pulled ${live/#$HOME/\~}"
  elif [ -L "$live" ]; then echo "  skip   ${live/#$HOME/\~} (already a symlink into the repo)"
  else echo "  absent ${live/#$HOME/\~}"; fi
done

if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  rsync -a --delete --exclude '.git' "$HOME/.config/nvim/" "$DOTFILES/config/nvim/"
  echo "  pulled ~/.config/nvim"
fi

# Installed packages, so the other machine can see what it is missing.
brew leaves > "$DOTFILES/inventory/$(scutil --get ComputerName 2>/dev/null || hostname)-leaves.txt" 2>/dev/null || true
ls "$HOME/Library/Application Support/Zed/extensions/installed" \
   > "$DOTFILES/inventory/$(scutil --get ComputerName 2>/dev/null || hostname)-zed-extensions.txt" 2>/dev/null || true

echo; echo "now: git -C '$DOTFILES' diff"
