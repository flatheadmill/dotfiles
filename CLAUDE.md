# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages shell, Git, Vim, and tmux configurations using a two-layer approach:
- **`skel/`**: Minimal skeleton files installed to `$HOME` that source from both shared and machine-specific locations
- **`etc/`**: Shared configuration content
- **`~/.local/etc/`**: Machine-specific configuration (not in repo)

## Installation and Setup

The repository includes a comprehensive POSIX shell installer:

```bash
# Run the installer (backs up existing files to ~/.local/var/dotfiles/replaced/[timestamp])
./install.sh
```

The installer performs these steps:
1. Creates local directory structure
2. Verifies Git and SSH access to GitHub
3. Clones the repository to `~/.dotfiles`
4. Backs up existing configuration files
5. Installs skeleton files
6. Downloads dependencies (vim-plug, zsh-minimal theme, TPM, aphrodite theme)

## Key Directories

- **`bin/`**: Custom scripts and utilities added to PATH
- **`fu/`**: Git workflow helper scripts (branch management, PR creation, changelog generation)
- **`lib/`**: Library functions and modules
- **`completions/`**: Shell completion scripts
- **`etc/`**: Main configuration files sourced by skeleton files
- **`got/`**: External dependencies (third-party configurations)

## Git Workflow Tools

The `fu/` directory contains Git workflow helpers:
- `gh-pr-create`: Create GitHub pull requests
- `gh-pr-merge`: Merge GitHub pull requests
- `branch-changes`: Show changes in a branch
- `merge-from`/`merge-into`: Branch merging utilities
- `changelog`: Generate changelogs

## Configuration Architecture

Configuration files follow this pattern:
1. Skeleton file in `$HOME` (e.g., `~/.zshrc`)
2. Sources from `~/.dotfiles/etc/` (shared config)
3. Sources from `~/.local/etc/` (machine-specific config)

This allows for both shared and machine-specific configurations without modifying the repository.

## macOS tmux Unicode Setup

For proper Unicode support in tmux on macOS:
1. Set iTerm2 to "Use Unicode version 9 widths"
2. Build tmux from source with UTF-8 support:
```bash
brew install utf8proc
brew install --build-from-source tmux --interactive
# In the interactive shell:
./configure --enable-utf8proc --prefix=/usr/local/Cellar/tmux/[version]
make install
exit
```

## Path Management

The configuration carefully manages PATH order, with support for:
- Homebrew (macOS)
- ASDF version manager
- Cargo (Rust)
- Go
- Local bin directories

## Security Notes

- SSH signing is configured for Git commits
- GitHub's SSH fingerprint is verified during installation
- The installer backs up all existing files before replacement