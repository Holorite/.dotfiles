# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed with GNU Stow. Top-level package directories (`nvim/`, `zsh/`, `git/`, `tmux/`) mirror `$HOME` layout and are symlinked into place by `stow`. `install/` holds per-tool bootstrap scripts. `windows/` and `windows_setup.ps1` are for Windows Terminal only.

## Common commands

```sh
./install.sh              # stow only (default)
./install.sh list         # list available installers
./install.sh <name>       # run one installer, then stow
./install.sh all          # run every installer, then stow
./install.sh all-confirm  # prompt Y/n per installer, then stow
./install.sh missing      # run every installer non-interactively (REINSTALL=0), installing only what's absent
REINSTALL=1 ./install.sh <name>  # force reinstall a tool that's already present
```

The stow step always runs at the end and links `nvim zsh git tmux` into `$HOME`.

## DOTFILES_ENV

First run prompts for an environment and writes the choice to `~/.dotfiles_env`. Valid values: `work-argos`, `work-devcompute`, `home`. The variable is exported before installers run, sourced by `.zshrc`, and read by `nvim/.config/nvim/init.lua`. Behavior gated on it:

- `install/lib.sh:ensure_brew` — Linuxbrew is bootstrapped/used only when `use_brew` returns true (currently `home`). `try_brew` returns 1 elsewhere so installers fall back to `eget`.
- `.utils.sh` (repo root, non-stowed) defines `use_brew()` — the canonical brew-vs-fallback gate. Sourced by both `install/lib.sh` and `zsh/.zshrc` so installers and the live shell agree. Use it instead of inlining the env check.
- `.utils.sh` also defines `workspace_dir()` — the canonical big-disk root for the env (home is small on work hosts): `/local/mnt/workspace/juliray` (devcompute), `/prj/qct/mlsys/markham/scratch/juliray` (argos), `$HOME` elsewhere. Park large/regenerable data here and derive specific paths from it rather than re-checking the env. Built on it: `nvm_dir()` → `$(workspace_dir)/.nvm` (used by `install/nvm/install.sh` and `zsh/conf.d/nvm.zsh`); `zsh/conf.d/python.zsh` exports `PIP_CACHE_DIR`, `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR` under `$(workspace_dir)` to keep pip/uv off home.
- `zsh/env/<env>.zsh` is sourced after `conf.d/*.zsh` for env-specific paths/aliases.
- `git/.gitconfig.<env>` is symlinked to `~/.gitconfig.local` (included by `git/.gitconfig`).
- `init.lua` configures `clangd` to run via `./run-in-docker` on the work envs, plain `clangd` on home.

When adding env-conditional logic, follow these existing seams rather than introducing new env checks.

## Installer conventions (`install/<name>/install.sh`)

Every installer sources `install/lib.sh` and follows the same shape. Use the helpers — don't reinvent them:

- `should_install <cmd> [version-cmd...]` / `should_install_path <name> <path>` — gates the install. Honors `REINSTALL=1`; silently skips when stdin isn't a TTY.
- `try_brew <formula>` — installs via brew on `home`, returns 1 elsewhere so callers fall back. brew failures are fatal (treated as a config bug, not transient).
- `ensure_eget` + `eget_install <gh-repo> --to "$BIN_DIR"` — the standard non-brew fallback. The wrapper anti-matches `.deb`/`.rpm`/`.apk` so eget doesn't prompt; pass extra `--asset` flags to disambiguate further (e.g. gnu vs musl, arm64 vs x86_64). Binaries land in `$HOME/.local/bin`.
- `info` / `error` for logging; `error` exits non-zero.

All installer scripts run with `set -euo pipefail`.

New `install/<name>/install.sh` files must be `chmod +x` — the dispatcher in `install.sh` only picks up executable installers (silently skips otherwise).

## Zsh layout

`zsh/.zshrc` is intentionally tiny. It loads, in order: secrets (`zsh/.zsh_secrets`, gitignored) → antidote plugins (`.zsh_plugins.txt`) → every `conf.d/*.zsh` fragment → the matching `env/<DOTFILES_ENV>.zsh` → `starship init`. Add new shell behavior as a fragment in `conf.d/` (general) or `env/` (env-specific), not inline in `.zshrc`.

## Neovim layout

`nvim/.config/nvim/` is stow-ed to `~/.config/nvim`. `init.lua` sets options/keymaps and bootstraps `lazy.nvim` via `lua/config/lazy.lua`; each plugin spec is its own file under `lua/plugins/`. `lazy-lock.json` is committed.

## Repo-specific git config

`install.sh` pins `user.email = julian.r8y@gmail.com` on this repo (overrides any work email a global gitconfig might set). `git/.gitconfig` sets `status.showUntrackedFiles = no`, so `git status` here hides untracked files by default — use `git status -u` when you need to see them.

## Files that aren't stow-ed

`.stow-local-ignore` (top-level and per-package) excludes things like `install.sh`, `.git`, `.zsh_secrets`, and `.gitconfig.local` from symlinking. Adding a new file at a package root that *shouldn't* land in `$HOME` requires adding it to the relevant `.stow-local-ignore`.
Any file that is sourced in a stowed module via a direct path to the dotfiles folder should not be stowed.
