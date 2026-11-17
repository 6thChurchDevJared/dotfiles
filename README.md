# dotfiles

Shell, terminal and editor configuration for a work MacBook Pro, a personal Mac Mini, and Debian-family Linux boxes (Raspberry Pi 4, Proxmox guests). One config on all of them; only package installation differs by OS.

**The Mac Mini drives.** For anything shared, the Mini is the source of truth and the MacBook Pro follows. The one thing the Mini must never disturb is the MacBook's Python toolchain, so that lives in an untracked machine-local file. See [MACHINES.md](MACHINES.md).

## Layout

```
shell/common.zsh    shared: aliases, history, completion, oxide tools
shell/zshrc         thin loader: common -> ~/.zshrc.local -> syntax highlighting
shell/zprofile      Homebrew env if present (static, avoids the 45ms brew shellenv fork)
shell/zshenv        rust env, if rustup is installed
git/gitconfig       shared; identity is included from ~/.gitconfig.local
config/             ghostty, zed, zellij, nvim, starship
bin/                your scripts, on PATH everywhere; `newscript` makes new ones
templates/          script templates newscript copies (bash, uv Python)
deepwork/           macOS deep-work toggles, linked into ~/.deepwork
local/*.example     templates for the untracked machine-local files
Brewfile            shared packages (macOS)
packages/linux.sh   the same toolset on Debian/Pi OS/Ubuntu: apt + GitHub releases
Brewfile.macbook    work-only (pyenv, aws-sam-cli, helm, vault, gopass, llvm)
Brewfile.mini       personal-only (music production etc., to be filled in)
inventory/          `brew leaves` and Zed extensions per machine, for diffing
install.sh          symlink into $HOME, with backups
collect.sh          pull this machine's live configs back into the repo
```

## Set up a machine

```bash
git clone <repo-url> ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh --dry-run     # read this first
./install.sh --packages    # brew bundle on macOS, packages/linux.sh on Linux
exec zsh
```

On Linux, clone anywhere (the shell finds the repo from the `~/.zshrc` symlink), then `chsh -s "$(command -v zsh)"`. Re-run `packages/linux.sh` to update the Linux tools; on macOS it is `brew upgrade`. Use the 64-bit Raspberry Pi OS image: the script refuses 32-bit ARM, and the Trixie-based release gets far newer packages than Bookworm.

`install.sh` is idempotent and never destroys anything: an existing real file is moved to `<name>.bak.<timestamp>` before the symlink is made. It also seeds `~/.zshrc.local` and `~/.gitconfig.local` from `local/` if they do not exist, and clones the two zsh plugins.

## Vim workflow

- **Shell** is in vi mode. `Esc` for normal mode (block cursor), `v` there opens the command line in nvim. `Ctrl-A/E/W/U` still work in insert mode.
- **Editor** is nvim (LazyVim) for `$EDITOR`, `vi`, `vim` and man pages. First launch installs plugins and LSP servers. Start with `:Tutor`. Language extras are in `config/nvim/lazyvim.json`, add more with `:LazyExtras`.
- **Panes** are zellij, unlock-first: it starts locked so every key reaches nvim. `Alt h/j/k/l` moves between panes, `Alt n` new pane, `Alt f` floating pane. `Ctrl g` is the leader: then `p` pane, `t` tab, `n` resize, `m` move, `s` scroll/search, `o` session. Inside nvim, `Ctrl h/j/k/l` moves between nvim splits.
- **Scripts**: `newscript name` (bash) or `newscript name.py` (uv inline-deps Python) creates `bin/name`, executable and on PATH, and opens it. Commit it and it is on every machine. `--here` creates it in the current directory instead.

## Reconcile the two machines

The Mini is authoritative, so changes flow Mini to main to MacBook.

```bash
# on the Mac Mini
git checkout -b mini
./collect.sh                       # pulls live configs into the repo
git add -A && git commit -m "mini: as-installed" && git push -u origin mini
```

Then merge `mini` into `main`, letting the Mini win on the shared files, and `git pull && ./install.sh` on the MacBook Pro.

If you would rather not put this on a remote, `./collect.sh --dump` prints one pasteable bundle: machine, macOS version, `brew leaves`, casks, Zed extensions, and every shared config file with a `### FILE` delimiter. Paste that into a session and it can be reconciled by hand.

## What is not here

Credentials, and anything that stores them. `~/.config/gh/hosts.yml`, `~/.config/containers/auth.json`, `~/.aws`, `~/.kube`, `~/.ssh`, `~/.config/gopass` are excluded and blocked by `.gitignore`. Configuration only.

**Keep the remote private.** This is work-machine configuration; it contains internal paths and tool choices even with the secrets stripped.
