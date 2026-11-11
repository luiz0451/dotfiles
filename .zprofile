# Login shells (Ghostty and every tmux pane): PATH and fpath, set once.
typeset -U path fpath

# Homebrew: PATH, MANPATH, INFOPATH and its zsh completions on fpath.
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Docker Desktop CLI
path+=("$HOME/.docker/bin")

# coursier install directory
path+=("$HOME/Library/Application Support/Coursier/bin")

# OrbStack: command-line tools and integration
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

# Obsidian CLI
[[ -d /Applications/Obsidian.app ]] && path+=(/Applications/Obsidian.app/Contents/MacOS)

# Personal scripts first.
path=("$HOME/.local/bin" $path)
