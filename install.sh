#!/usr/bin/env bash
# Dotfiles installer for macOS. Safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/luiz0451/dotfiles/master/install.sh | bash
#
# Overrides: DOTFILES_REPO (clone URL), DOTFILES_BRANCH (default: master).
set -Eeuo pipefail

REPO="${DOTFILES_REPO:-https://github.com/luiz0451/dotfiles.git}"
BRANCH="${DOTFILES_BRANCH:-master}"
GIT_DIR_PATH="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
BREW=""

if [[ -t 1 ]]; then BLUE=$'\033[1;34m'; RESET=$'\033[0m'; else BLUE=""; RESET=""; fi
log() { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
trap 'printf "error: install failed at line %s\n" "$LINENO" >&2' ERR

dot() { git --git-dir="$GIT_DIR_PATH" --work-tree="$HOME" "$@"; }

ensure_prerequisites() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this installer supports macOS only"
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    die "install the Command Line Tools in the dialog that just opened, then re-run"
  fi
  command -v git >/dev/null 2>&1 || die "git not found"
  command -v zsh >/dev/null 2>&1 || die "zsh not found"
}

ensure_brew() {
  log "Homebrew"
  if command -v brew >/dev/null 2>&1; then
    BREW="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    BREW=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    BREW=/usr/local/bin/brew
  else
    printf '  installing Homebrew\n'
    # The installer prompts: give it the terminal, since stdin may be this script.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
    if [[ -x /opt/homebrew/bin/brew ]]; then BREW=/opt/homebrew/bin/brew; else BREW=/usr/local/bin/brew; fi
  fi
  eval "$("$BREW" shellenv)"
}

install_packages() {
  log "Packages"
  # omp comes from a third-party tap; Homebrew will not load it until trusted.
  "$BREW" tap can1357/tap </dev/null
  "$BREW" trust --formula can1357/tap/omp </dev/null
  local brewfile
  brewfile="$(mktemp -t dotfiles-brewfile.XXXXXX)"
  cat >"$brewfile" <<'EOF'
# shell
brew "tmux"
brew "starship"
brew "eza"
brew "fzf"
brew "zoxide"
brew "fd"
brew "ripgrep"
brew "bat"
brew "atuin"
brew "direnv"
brew "git-delta"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
# apps
brew "yazi"
brew "jq"
brew "lazygit"
brew "can1357/tap/omp"
# neovim and what its config calls
brew "neovim"
brew "tree-sitter-cli"
brew "imagemagick"
brew "ruff"
brew "pyright"
brew "typescript-language-server"
brew "lua-language-server"
brew "rust-analyzer"
EOF
  "$BREW" bundle --no-upgrade --file="$brewfile" </dev/null
  rm -f -- "$brewfile"

  if [[ -d /Applications/Ghostty.app ]]; then
    printf '  Ghostty already installed\n'
  else
    "$BREW" install --cask ghostty </dev/null
  fi
}

# True when $target already has exactly the content the repo has at HEAD.
same_as_head() {
  local rel="$1" target="$2"
  [[ -f "$target" && ! -L "$target" ]] || return 1
  git --git-dir="$GIT_DIR_PATH" show "HEAD:$rel" | cmp -s - "$target"
}

backup_collisions() {
  local moved=0 entry rel target
  while IFS= read -r -d '' entry; do
    rel="${entry#*$'\t'}"
    target="$HOME/$rel"
    if [[ -e "$target" || -L "$target" ]] && ! same_as_head "$rel" "$target"; then
      mkdir -p -- "$(dirname -- "$BACKUP_DIR/$rel")"
      mv -- "$target" "$BACKUP_DIR/$rel"
      printf '  moved %s -> %s\n' "$target" "$BACKUP_DIR/$rel"
      moved=1
    fi
  done < <(git --git-dir="$GIT_DIR_PATH" ls-tree -r -z HEAD)
  [[ "$moved" -eq 1 ]] || printf '  no conflicting files\n'
}

install_dotfiles() {
  log "Dotfiles ($REPO, branch $BRANCH)"
  if [[ -e "$GIT_DIR_PATH" ]]; then
    [[ "$(git --git-dir="$GIT_DIR_PATH" rev-parse --is-bare-repository 2>/dev/null)" == "true" ]] \
      || die "$GIT_DIR_PATH exists but is not a bare repository"
    [[ -z "$(dot status --porcelain=v1 --untracked-files=no)" ]] \
      || die "tracked dotfiles have local changes; commit or stash them, then re-run"
    dot fetch origin "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH"
    dot merge --ff-only "origin/$BRANCH"
    return
  fi

  git clone --bare --branch "$BRANCH" "$REPO" "$GIT_DIR_PATH"
  dot config --local status.showUntrackedFiles no
  dot config --local remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  dot config --local "branch.$BRANCH.remote" origin
  dot config --local "branch.$BRANCH.merge" "refs/heads/$BRANCH"
  dot fetch --quiet origin

  backup_collisions
  dot checkout --force
}

install_zsh_plugins() {
  log "Oh My Zsh and fzf-tab"
  if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    printf '  Oh My Zsh already installed\n'
  else
    [[ ! -e "$HOME/.oh-my-zsh" ]] || die "$HOME/.oh-my-zsh exists but is not Oh My Zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi

  local fzf_tab="$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
  if [[ -d "$fzf_tab" ]]; then
    printf '  fzf-tab already installed\n'
  else
    git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$fzf_tab"
  fi
}

bootstrap_neovim() {
  log "Neovim plugins and treesitter parsers"
  # init.lua installs the plugins on first start; then build every parser.
  nvim --headless \
    "+lua require('nvim-treesitter').install(vim.g.treesitter_parsers):wait(600000)" \
    +qa </dev/null
}

main() {
  ensure_prerequisites
  ensure_brew
  install_packages
  install_dotfiles
  install_zsh_plugins
  bootstrap_neovim
  log "Done. Open a new terminal, or run: exec zsh"
}

main "$@"
