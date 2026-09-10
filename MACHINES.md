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

## Notes on the current state

`starship.toml` is in the repo but starship is **not installed and not initialised** — the prompt is the literal `PROMPT='%~ # '` in `common.zsh`. Keep that in mind before debugging a prompt problem; on this machine starship has been a red herring before.

`~/.config/nvim` is a LazyVim starter that was cloned as its own git repo. The files are copied in here without their `.git`, so the repo owns them now.

`~/.cargo/bin` is empty. Every "rust replacement" (eza, bat, fd, ripgrep, zoxide, delta, zellij) came from Homebrew, so the `Brewfile` is the whole install story. Rust itself is installed via rustup and `~/.zshenv` sources its env if present.

Zed's 32 extensions are not installed by `install.sh`; they are declared in `config/zed/settings.json` under `auto_install_extensions`, which Zed acts on at startup.
