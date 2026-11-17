#!/usr/bin/env bash
# Install the shared CLI toolset on Debian-family Linux: Debian 12/13,
# Raspberry Pi OS (64-bit), Ubuntu, and Proxmox guests. The macOS equivalent is
# the Brewfile. Re-running it is how you update: apt upgrades what it owns and
# the GitHub-release tools are re-fetched at their latest version.
#
# Usage: packages/linux.sh [--dry-run]
#
# Source per tool:
#   apt             when the distro's package exists (eza, delta, starship and
#                   lazygit are missing on Debian 12 / bookworm)
#   GitHub release  neovim always (LazyVim needs a newer one than Debian ships),
#                   zellij and uv always (not packaged), plus any apt miss above.
#                   Unpacked into ~/.local/opt, linked into ~/.local/bin.
set -euo pipefail

DRY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  -h | --help)
    sed -n '2,/^set /{/^set /d;s/^# \{0,1\}//;p;}' "$0"
    exit 0
    ;;
  "") ;;
  *)
    echo "unknown flag: $1" >&2
    exit 2
    ;;
esac

say() { printf '  %s\n' "$*"; }
run() { if ((DRY)); then say "would: $*"; else "$@"; fi; }

command -v apt-get >/dev/null || {
  echo "no apt-get: only Debian-family Linux is handled" >&2
  exit 1
}
SUDO=""
[[ $EUID -eq 0 ]] || SUDO=sudo

case "$(uname -m)" in
  aarch64 | arm64) ARCH=aarch64 ;;
  x86_64 | amd64) ARCH=x86_64 ;;
  *)
    echo "unsupported arch $(uname -m). On a Pi, use the 64-bit Raspberry Pi OS image." >&2
    exit 1
    ;;
esac

LOCAL="$HOME/.local"
BASE=(zsh git curl ca-certificates tar gzip less)
# apt package name -> fall back to GitHub when the distro lacks it
WANT=(ripgrep fd-find bat fzf zoxide eza git-delta starship lazygit shellcheck shfmt)

has_candidate() {
  [[ "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}')" =~ ^[0-9] ]]
}

latest_tag() { # latest_tag owner/repo -> tag, from the /releases/latest redirect (no API quota)
  curl -fsSI "https://github.com/$1/releases/latest" |
    awk -F/ 'tolower($1) ~ /^location:/ {print $NF}' | tr -d '\r'
}

gh_install() { # gh_install <name> <owner/repo> <asset> <path-of-binary-inside-archive>...
  local name="$1" repo="$2" asset="$3"
  shift 3
  local dir="$LOCAL/opt/$name" url="https://github.com/$repo/releases/latest/download/$asset"
  say "github  $name <- $url"
  ((DRY)) && return 0
  rm -rf "$dir" && mkdir -p "$dir" "$LOCAL/bin"
  curl -fsSL "$url" | tar -xz -C "$dir"
  local bin
  for bin in "$@"; do ln -sfn "$dir/$bin" "$LOCAL/bin/${bin##*/}"; done
}

echo "apt:"
run $SUDO apt-get update -qq
apt_pkgs=("${BASE[@]}") missing=()
for p in "${WANT[@]}"; do
  if has_candidate "$p"; then apt_pkgs+=("$p"); else missing+=("$p"); fi
done
say "install ${apt_pkgs[*]}"
run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${apt_pkgs[@]}"
((${#missing[@]})) && say "not in apt here, using GitHub: ${missing[*]}"

echo "github releases:"
nv="nvim-linux-${ARCH/aarch64/arm64}"
gh_install neovim neovim/neovim "$nv.tar.gz" "$nv/bin/nvim"
gh_install zellij zellij-org/zellij "zellij-$ARCH-unknown-linux-musl.tar.gz" zellij
gh_install uv astral-sh/uv "uv-$ARCH-unknown-linux-gnu.tar.gz" \
  "uv-$ARCH-unknown-linux-gnu/uv" "uv-$ARCH-unknown-linux-gnu/uvx"

for p in "${missing[@]}"; do
  case "$p" in
    eza) gh_install eza eza-community/eza "eza_$ARCH-unknown-linux-gnu.tar.gz" eza ;;
    starship) gh_install starship starship/starship "starship-$ARCH-unknown-linux-musl.tar.gz" starship ;;
    git-delta)
      t="$(latest_tag dandavison/delta)"
      gh_install delta dandavison/delta "delta-$t-$ARCH-unknown-linux-gnu.tar.gz" \
        "delta-$t-$ARCH-unknown-linux-gnu/delta"
      ;;
    lazygit)
      t="$(latest_tag jesseduffield/lazygit)"
      gh_install lazygit jesseduffield/lazygit \
        "lazygit_${t#v}_Linux_${ARCH/aarch64/arm64}.tar.gz" lazygit
      ;;
    *) say "skip    $p (no GitHub fallback defined)" ;;
  esac
done

# Debian renames these to avoid old package clashes. Link the real names so
# scripts, fzf previews and muscle memory all work.
echo "debian names:"
for pair in bat:batcat fd:fdfind; do
  real="${pair%%:*}" deb="${pair##*:}"
  if ! command -v "$real" >/dev/null && command -v "$deb" >/dev/null; then
    say "link    ~/.local/bin/$real -> $(command -v "$deb")"
    run ln -sfn "$(command -v "$deb")" "$LOCAL/bin/$real"
  fi
done

echo
login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
[[ $login_shell == */zsh ]] || echo "  login shell is $login_shell. Switch: chsh -s $(command -v zsh || echo /usr/bin/zsh)"
echo "  ~/.local/bin must be on PATH (common.zsh does this). Open a new shell."
