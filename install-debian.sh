#!/usr/bin/env bash
# Debian server bootstrap for the `server` branch of the dotfiles. Safe to re-run:
# `up` calls it to bring every tool to its latest release.
#
# No root needed: apt provides zsh, tmux, git, eza, fzf, zoxide, ripgrep,
# lazygit, starship, zsh-autosuggestions and zsh-syntax-highlighting; everything
# else lands in ~/.local (binaries in ~/.local/bin, Neovim in ~/.local/opt/nvim).
set -Eeuo pipefail

BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p -- "$BIN" "$OPT"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# latest_tag owner/repo: tag name of the latest GitHub release.
latest_tag() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name; }

# have NAME VERSION: true when NAME --version already reports VERSION.
have() { [[ -x "$BIN/$1" ]] && "$BIN/$1" --version 2>/dev/null | grep -qF -- "${2#v}"; }

# from_tarball NAME URL: install the executable NAME found inside the tarball.
from_tarball() {
  local name="$1" url="$2" dir="$TMP/$1"
  mkdir -p -- "$dir"
  curl -fsSL "$url" | tar xz -C "$dir"
  install -m 755 "$(find "$dir" -type f -name "$name" | head -n1)" "$BIN/$name"
}

tool() {
  local name="$1" repo="$2" asset="$3" tag
  tag="$(latest_tag "$repo")"
  if have "$name" "$tag"; then printf '  %s %s already installed\n' "$name" "$tag"; return; fi
  log "$name $tag"
  local url="https://github.com/$repo/releases/download/$tag/${asset//\{tag\}/$tag}"
  if [[ $url == *.tar.gz ]]; then from_tarball "$name" "$url"
  else curl -fsSL -o "$BIN/$name" "$url" && chmod 755 "$BIN/$name"; fi
}

tool atuin  atuinsh/atuin    'atuin-x86_64-unknown-linux-gnu.tar.gz'
tool direnv direnv/direnv    'direnv.linux-amd64'
tool delta  dandavison/delta 'delta-{tag}-x86_64-unknown-linux-gnu.tar.gz'
tool bat    sharkdp/bat      'bat-{tag}-x86_64-unknown-linux-gnu.tar.gz'

# uv: Astral's installer; it updates itself when already present.
if [[ -x "$BIN/uv" ]]; then
  log "uv"; "$BIN/uv" self update
else
  log "uv"; curl -fsSL https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

# Neovim: the whole release tree in ~/.local/opt/nvim, linked into ~/.local/bin.
tag="$(latest_tag neovim/neovim)"
if have nvim "$tag"; then
  printf '  nvim %s already installed\n' "$tag"
else
  log "nvim $tag"
  curl -fsSL "https://github.com/neovim/neovim/releases/download/$tag/nvim-linux-x86_64.tar.gz" | tar xz -C "$TMP"
  rm -rf -- "$OPT/nvim"
  mv -- "$TMP/nvim-linux-x86_64" "$OPT/nvim"
  ln -sfn "$OPT/nvim/bin/nvim" "$BIN/nvim"
fi

# Oh My Zsh and fzf-tab (the Mac's .zshrc loads both).
if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  log "Oh My Zsh"; git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
fzf_tab="$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
if [[ ! -d "$fzf_tab" ]]; then
  log "fzf-tab"; git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$fzf_tab"
fi

# .gitattributes keeps the server's .tmux.conf on `git merge master`; that
# needs the "ours" merge driver defined in this clone.
git --git-dir="$HOME/.dotfiles.git" config merge.ours.driver true
