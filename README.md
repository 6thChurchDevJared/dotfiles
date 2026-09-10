# dotfiles

Shell, terminal and editor configuration for two machines: a work MacBook Pro and a personal Mac Mini.

**The Mac Mini drives.** For anything shared, the Mini is the source of truth and the MacBook Pro follows. The one thing the Mini must never disturb is the MacBook's Python toolchain, so that lives in an untracked machine-local file. See [MACHINES.md](MACHINES.md).

## Layout

```
shell/common.zsh    shared: aliases, history, completion, oxide tools
shell/zshrc         thin loader: common -> ~/.zshrc.local -> syntax highlighting
shell/zprofile      Homebrew env (static, avoids the 45ms brew shellenv fork)
shell/zshenv        rust env, if rustup is installed
git/gitconfig       shared; identity is included from ~/.gitconfig.local
config/             ghostty, zed, zellij, nvim, starship
bin/                deep-work toggles
local/*.example     templates for the untracked machine-local files
Brewfile            shared packages
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
./install.sh --brew
exec zsh
```

`install.sh` is idempotent and never destroys anything: an existing real file is moved to `<name>.bak.<timestamp>` before the symlink is made. It also seeds `~/.zshrc.local` and `~/.gitconfig.local` from `local/` if they do not exist, and clones the two zsh plugins.

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
