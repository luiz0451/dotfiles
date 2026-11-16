# ~/.zshrc -- interactive shells only. PATH lives in ~/.zprofile / ~/.zshenv.

# 1. Environment
export EDITOR=nvim VISUAL=nvim
export BAT_THEME=ansi                       # bat/man/fzf previews use the terminal's 16 colors
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT=-c
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"

# 2. Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                                # prompt comes from starship
zstyle ':omz:update' mode disabled          # update by hand: omz update
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p ${ZSH_COMPDUMP:h}
ZOXIDE_CMD_OVERRIDE=cd                      # zoxide takes over cd: `cd blog` jumps, `cdi` picks

plugins=(
  git
  vi-mode
  history-substring-search
  sudo                  # Esc Esc: prefix the line with sudo
  extract               # x <archive>
  direnv                # per-directory .envrc
  zoxide                # cd <dir|keyword>, cdi
  fzf                   # keep last: Ctrl-T / Alt-C override vi-mode's (Ctrl-R goes to atuin below)
)

source "$ZSH/oh-my-zsh.sh"

# 3. Shell behaviour
KEYTIMEOUT=1                                # vi-mode: Esc takes effect after 10ms, not 400ms
setopt AUTO_CD                              # `dir` == `cd dir`
setopt INTERACTIVE_COMMENTS                 # allow # comments at the prompt
setopt NO_BEEP

# 4. History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY                     # timestamps
setopt SHARE_HISTORY                        # live-share across sessions
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE                    # a leading space keeps a command out of history
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY                          # !! expands in the buffer, no blind run

# 5. Completion
zstyle ':completion:*' menu no              # fzf-tab draws the menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '-- %d --'
zstyle ':completion:*:warnings' format 'no matches for: %d'

# fzf-tab: fzf-powered Tab menu. After compinit, before the plugins that wrap
# widgets (autosuggestions, highlighting).
[[ -r $ZSH/custom/plugins/fzf-tab/fzf-tab.plugin.zsh ]] && source $ZSH/custom/plugins/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always $realpath'

# 6. Keys: Up/Down (and k/j in vi command mode) search history for what is typed.
for _k in '^[[A' '^[OA'; do bindkey $_k history-substring-search-up;   bindkey -M viins $_k history-substring-search-up;   done
for _k in '^[[B' '^[OB'; do bindkey $_k history-substring-search-down; bindkey -M viins $_k history-substring-search-down; done
unset _k
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# 7. Prompt (~/.config/starship.toml)
eval "$(starship init zsh)"

# Atuin: searchable history on Ctrl-R. Up-arrow stays with history-substring-search.
eval "$(atuin init zsh --disable-up-arrow)"

# 8. Command feedback (highlighting must load last). Homebrew on macOS,
# /usr/share on Debian.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
for _p in zsh-autosuggestions/zsh-autosuggestions.zsh zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  for _d in /opt/homebrew/share /usr/share; do
    [[ -r $_d/$_p ]] && { source $_d/$_p; break }
  done
done
unset _p _d

# 9. Aliases
alias ls='eza'
alias ll='eza -lah --git'
alias la='eza -a'
alias lt='eza --tree --level=2'
alias cat='bat -pp'                         # plain + no pager: like cat, with colours on a tty
alias vim='nvim'
alias lg='lazygit'
alias ompr='omp --resume'

# List the new directory after every cd, `..` or y (interactive shells only: this is ~/.zshrc).
_ls_after_cd() { eza }
chpwd_functions+=(_ls_after_cd)

# Open Yazi and cd into the directory it was in when quitting.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  [[ -n $cwd && $cwd != $PWD ]] && cd -- "$cwd"
  rm -f -- "$tmp"
}

# clone <url> [group]: clone into ~/git/<group> and cd in. The group comes from
# the host (forgejo, github, codeberg) unless given, e.g. `clone <url> elattes`.
# Shortcuts from git's url.insteadOf work: `clone fj:bsh`.
clone() {
  (( $# )) || { print -u2 'usage: clone <url> [group]'; return 2 }
  local url group repo
  url=$(git ls-remote --get-url "$1")        # expands insteadOf shortcuts
  group=$2
  if [[ -z $group ]]; then
    case $url in
      *forgejo*)      group=forgejo ;;
      *github.com*)   group=github ;;
      *codeberg.org*) group=codeberg ;;
      *) print -u2 "clone: unknown host in $url; pass the group: clone <url> <group>"; return 2 ;;
    esac
  fi
  repo=${${url:t}%.git}
  mkdir -p ~/git/$group && git -C ~/git/$group clone "$url" && cd ~/git/$group/$repo
}

# up: update what lives outside the dotfiles, one step after another. macOS:
# Homebrew and tmux plugins; Debian: ~/install-debian.sh (user-space tools).
# Both: Oh My Zsh, fzf-tab, Neovim plugins and treesitter parsers.
# Lists the Neovim plugin changes at the end and which steps failed, if any.
up() {
  local -a failed
  local log="$HOME/.local/state/nvim/nvim-pack.log" before=0
  [[ -f $log ]] && before=$(wc -c <"$log")

  if [[ $OSTYPE == darwin* ]]; then
    print -P '%B==> Homebrew%b'
    { brew update && brew upgrade } || failed+=(brew)
    print -P '\n%B==> tmux plugins%b'
    /opt/homebrew/opt/tpm/share/tpm/bin/update_plugins all || failed+=(tmux)
  elif [[ -x ~/install-debian.sh ]]; then
    print -P '%B==> Tools (~/install-debian.sh)%b'
    ~/install-debian.sh || failed+=(tools)
  fi
  print -P '\n%B==> Oh My Zsh%b'
  "$ZSH/tools/upgrade.sh" || failed+=(oh-my-zsh)
  print -P '\n%B==> fzf-tab%b'
  git -C "$ZSH/custom/plugins/fzf-tab" pull --ff-only || failed+=(fzf-tab)
  print -P '\n%B==> Neovim plugins and parsers%b'
  nvim --headless '+lua vim.pack.update(nil, { force = true })' \
    "+lua require('nvim-treesitter').update():wait(300000)" +qa || failed+=(nvim)
  [[ -f $log ]] && tail -c +$((before + 1)) "$log"

  if (( $#failed )); then print -P "\n%F{red}failed:%f ${(j:, :)failed}"; return 1; fi
  print -P '\n%F{green}everything up to date%f'
}

# Tint the background while an interactive SSH session is open
# (per pane inside tmux, which would otherwise swallow the OSC 11).
ssh() {
  if [[ -t 1 ]]; then
    if [[ -n $TMUX ]]; then tmux select-pane -P 'bg=#333233'
    else printf '\e]11;#333233\a'; fi
  fi
  command ssh "$@"
  local ret=$?
  if [[ -t 1 ]]; then
    if [[ -n $TMUX ]]; then tmux select-pane -P 'bg=default'
    else printf '\e]111\a'; fi
  fi
  return $ret
}

# Machine-specific additions (untracked on the Mac; the server branch tracks the
# Debian one). Last, so it can override anything above.
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
