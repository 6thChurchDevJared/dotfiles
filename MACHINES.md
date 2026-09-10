# What differs between the two machines, and why

The Mac Mini is the source of truth for shared configuration. When the two disagree about a file in `shell/common.zsh`, `config/` or `git/gitconfig`, the Mini wins. Everything that cannot be shared is listed here and lives in a machine-local file that is never committed.

## The Python toolchain is the one real conflict

The work MacBook Pro runs **pyenv with uv as a pyenv shim**, lazy-initialised so the prompt stays instant. That setup is load-bearing for work repos and must not be disturbed by anything the Mini pushes. It therefore lives in `~/.zshrc.local` (seeded from `local/zshrc.local.macbook.example`), not in `shell/common.zsh`.

The Mini can use whatever it likes. If uv alone is enough there, its `~/.zshrc.local` can stay empty, because uv installs into `~/.local/bin` and `common.zsh` already puts that on PATH.

## Everything else that is machine-local

| Thing | MacBook Pro | Mac Mini | Where it lives |
|---|---|---|---|
| git identity | work email | personal email | `~/.gitconfig.local` |
| container runtime | podman, with `alias docker=podman` and `SAM_CLI_CONTAINER_RUNTIME` | Docker Desktop or none | `~/.zshrc.local` |
| AWS / Kubernetes / Vault / gopass | installed | not wanted | `Brewfile.macbook` |
| music production | none | to be filled in | `Brewfile.mini` |

## Things deliberately not in this repo

Credentials, and anything that stores them: `~/.config/gh/hosts.yml` (OAuth token), `~/.config/containers/auth.json` (registry logins), `~/.aws/`, `~/.kube/config`, `~/.ssh/`, `~/.config/gopass`. The `.gitignore` blocks these by name as a second line of defence. Configuration only.

## What the first Mini reconciliation changed (2026-09-10)

The Mini pushed a full rewrite of the Ghostty config — a "glass" theme with an explicit palette, 65% opacity, blur 26, and `adjust-cell-height`. That is the look now, on both machines.

**It also silently dropped six things that are fixes rather than preferences**, so they were restored in a `## Function` section appended below the Mini's block (Ghostty takes the last value for single-value keys, so appending wins):

| Restored | Why it is not optional |
|---|---|
| `grapheme-width-method = legacy` | The fix for Claude Code / TUI text overlap and ghosting on Ghostty 1.3+. Diagnosed the hard way; starship was the red herring |
| `keybind = shift+enter=text:\n` | Claude Code newline instead of submit |
| `shell-integration = zsh` + features | cursor shape, sudo askpass, window title |
| `macos-option-as-alt = true` | readline word-jump |
| `cmd+d` / `cmd+shift+d` / `cmd+w` | splits |

**The rule this establishes:** the Mini drives appearance. It does not drive fixes. When a config is rewritten wholesale rather than edited, diff it for functional keys before adopting.

`starship.toml` went from an 8-line stub to the Mini's 141-line glass theme, and the Mini actually has starship installed while the MacBook Pro does not. `common.zsh` now initialises starship **if it is present** and falls back to `PROMPT='%~ # '` otherwise, so neither machine errors.

The Mini runs three other tools that need shell init and were missing from `common.zsh`: **mise** (runtime versions — this is the Mini's answer to pyenv), **atuin** (syncable shell history, rebinds Ctrl-R) and **broot**. All three are now initialised, each guarded by `command -v`, so the block is a no-op on the MacBook Pro.

Package overlap is smaller than it looks: **7 formulae on both**, 16 MacBook-only, 31 Mini-only. `Brewfile` is now the true intersection plus starship; the rest are in the per-machine files. Adopting any Mini tool on the MacBook is one line moved into `Brewfile`.

**Open decision:** `config/zed/settings.json` declares 31 `auto_install_extensions` taken from the MacBook, and the Mini has one (`html`). Linking it on the Mini installs all 31, including helm, kubernetes-snippets and terraform, which have no personal use. Harmless but untidy — split the list if it bothers you.

## Notes on the current state

On the MacBook Pro starship is still not installed, so the prompt falls back to `PROMPT='%~ # '`. `brew bundle --file=Brewfile` installs it.

`~/.config/nvim` is a LazyVim starter that was cloned as its own git repo. The files are copied in here without their `.git`, so the repo owns them now.

`~/.cargo/bin` is empty. Every "rust replacement" (eza, bat, fd, ripgrep, zoxide, delta, zellij) came from Homebrew, so the `Brewfile` is the whole install story. Rust itself is installed via rustup and `~/.zshenv` sources its env if present.

Zed's 32 extensions are not installed by `install.sh`; they are declared in `config/zed/settings.json` under `auto_install_extensions`, which Zed acts on at startup.
