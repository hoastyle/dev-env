# Repository Guidelines

## Project Structure & Module Organization

The repository provides a modular ZSH development environment. Key directories:

* `config/` stores canonical `.zshrc` variants (`.zshrc`, `.zshrc.optimized`, `.zshrc.ultra-optimized`).
* `scripts/` contains automation entry points such as installers, launchers, and the performance optimizer; run everything from the repo root.
* `zsh-functions/` groups reusable helper modules (environment detection, enhanced search, utils, help, performance) sourced by the configs.
* `docs/` offers deep-dive references, troubleshooting, and configuration templates; `examples/` holds ready-to-use usage snippets.

## Build, Test, and Development Commands

Execute commands from the repository root:

* `./scripts/install_zsh_config.sh` installs the selected configuration into `~/.zshrc` with safety backups.
* `./scripts/zsh_launcher.sh normal|fast|minimal` launches ZSH in different performance profiles; append `benchmark` for startup timing.
* `./scripts/zsh_optimizer.sh analyze|optimize|restore|benchmark` inspects startup cost, applies tuned configs, and compares before/after metrics.
* `./scripts/zsh_tools.sh help` surfaces additional maintenance commands (`benchmark-detailed`, `quick-restore`).

## Coding Style & Naming Conventions

Shell and ZSH scripts use `#!/bin/bash` or `#!/usr/bin/env zsh`, `set -e`, and four-space indentation. Declare functions in snake_case, keep option flags lowercase, and prefer double quotes for expanded variables. Mirror the existing bilingual (EN/中文) inline documentation and reuse the colorized logging helpers for consistent UX.

## Testing Guidelines

No automated test harness exists; rely on scripted probes. Run `./scripts/zsh_launcher.sh benchmark` after changes to capture startup deltas, and include the summary table in review notes. Validate config syntax with `zsh -n config/.zshrc` (repeat for optimized variants). When touching helper modules, exercise the relevant command via an interactive shell and record observed output or regressions.

## Commit & Pull Request Guidelines

Follow Conventional Commits with optional scoped types (e.g., `feat(performance): 优化启动基准`). Keep summaries action-focused and prefer Chinese descriptions to match history. Pull requests should outline high-level intent, enumerate affected scripts/configs, attach benchmark results or terminal snippets, and reference related issues or docs when available.

## Configuration Safety Tips

Many scripts mutate `~/.zshrc`; rely on the built-in backup prompts and note the generated backup path in your PR. For experimental work, direct the launcher to a disposable `$HOME` by exporting `ZDOTDIR` before invoking scripts, and clean up auxiliary files created under `~/.zsh_*/` once validated.
