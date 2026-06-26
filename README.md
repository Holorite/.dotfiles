# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Fresh-clone bootstrap

```sh
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./install.sh all        # install every tool, then stow
exec zsh                # start a new shell
```

`DOTFILES_ENV` separates worskpace specific settings; saved to `~/.dotfiles_env`.
`stow` is bootstrapped automatically if it isn't already on `PATH`.

## Usage

```sh
./install.sh                     # stow only (default — no installers run)
./install.sh list                # list available installers and exit
./install.sh <name>              # run install/<name>/install.sh, then stow
./install.sh all                 # run every installer, then stow
./install.sh all-confirm         # prompt Y/n per installer, then stow
./install.sh missing             # run every installer in non-interactive mode,
                                 #   installing only what's absent (REINSTALL=0)
REINSTALL=1 ./install.sh <name>  # force reinstall a tool that's already present
```

The stow step always runs at the end and links `nvim zsh git tmux` into
`$HOME` (plus `claude` on non-home envs).

## DOTFILES_ENV

Selected on first run and written to `~/.dotfiles_env`. Valid values:
`work-argos`, `work-devcompute`, `home`. The variable is exported before
installers run, sourced by `.zshrc`, and read by `init.lua`. Behavior gated on
it lives behind canonical helpers in `.utils.sh` (`use_brew`, `workspace_dir`,
`nvm_dir`) and in `zsh/env/<env>.zsh` — see `CLAUDE.md` for the full breakdown.

## Layout

| Path                  | What it is                                                       |
| --------------------- | ---------------------------------------------------------------- |
| `nvim/`               | Neovim config (lazy.nvim); stow-ed to `~/.config/nvim`           |
| `zsh/`                | `.zshrc` + `conf.d/*.zsh` fragments + `env/<env>.zsh` overrides  |
| `git/`                | `.gitconfig` + per-env `.gitconfig.<env>`                        |
| `tmux/`               | `.tmux.conf` + custom `claude-agents/` pane tracker              |
| `install/`            | Per-tool bootstrap scripts (`install/<name>/install.sh`)         |
| `.utils.sh`           | Canonical env helpers, sourced by installers and the live shell  |
| `windows/`, `*.ps1`   | Windows Terminal only                                            |

## Conventions

See [`CLAUDE.md`](CLAUDE.md) for the detailed rules: installer shape
(`install/lib.sh` helpers, `chmod +x` requirement), the zsh load order, the
env seams, and what is intentionally not stow-ed.

Shell scripts are linted with `shellcheck` (`./install.sh shellcheck` to get
the binary). `./install.sh` installs a tracked `githooks/pre-commit` hook (via
`core.hooksPath`) that runs this on every commit — set `SKIP_SHELLCHECK=1` to
bypass:

```sh
shellcheck -S warning -e SC1091 install.sh install/lib.sh install/*/install.sh .utils.sh
```
