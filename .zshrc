# ~/.zshrc -- interactive shells only. Login PATH lives in ~/.zprofile / ~/.zshenv.

# 1. Environment
typeset -U path fpath                       # no duplicate PATH/fpath entries
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
path=($HOME/.local/bin $path)

# Homebrew completions (starship, eza, ...) must be on fpath before compinit.
[[ -d /opt/homebrew/share/zsh/site-functions ]] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Tools: editor, pager, fzf sources.
export EDITOR=nvim VISUAL=nvim
export BAT_THEME="Solarized (light)"
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

plugins=(
  git
  vi-mode
  history-substring-search
  sudo                  # Esc Esc: prefix the line with sudo
  extract               # x <archive>
  direnv                # per-directory .envrc
  zoxide                # z <dir>, zi
  fzf                   # keep last: Ctrl-R / Ctrl-T / Alt-C override vi-mode's
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

# 4b. ls/eza colors: Solarized-light-safe (a stale dark palette leaked in via tmux's global env)
export LS_COLORS='di=34:ln=36:ex=32:so=35:pi=33:bd=33:cd=33:or=31:mi=31:su=31:sg=31:tw=34:ow=34:st=34'
export LSCOLORS='exfxcxdxbxegedabagacad'

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
zstyle ':fzf-tab:complete:(z|zi):*' fzf-preview 'eza --tree --level=2 --color=always $realpath'

# 6. Keys: Up/Down (and k/j in vi command mode) search history for what is typed.
for _k in '^[[A' '^[OA'; do bindkey $_k history-substring-search-up;   bindkey -M viins $_k history-substring-search-up;   done
for _k in '^[[B' '^[OB'; do bindkey $_k history-substring-search-down; bindkey -M viins $_k history-substring-search-down; done
unset _k
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# 7. Prompt (pure preset: ~/.config/starship.toml)
eval "$(starship init zsh)"

# Atuin: searchable history on Ctrl-R. Up-arrow stays with history-substring-search.
eval "$(atuin init zsh --disable-up-arrow)"

# 8. Command feedback (brew plugins; highlighting must load last)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
[[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# 9. Aliases
alias ls='eza'
alias ll='eza -lah --git'
alias la='eza -a'
alias lt='eza --tree --level=2'
alias cat='bat -pp'                         # plain + no pager: like cat, with colours on a tty
alias vim='nvim'
alias lg='lazygit'

# Open Yazi and cd into the directory it was in when quitting.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  [[ -n $cwd && $cwd != $PWD ]] && cd -- "$cwd"
  rm -f -- "$tmp"
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
