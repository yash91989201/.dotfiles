# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias wezterm='flatpak run org.wezfurlong.wezterm'

# Add an "alert" alias for long running commands.
# Use like so:
# sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias e='nvim'

alias ec='cd ~/.dotfiles && nvim'
alias ee='cd ~/.dotfiles/nvim/.config/nvim && nvim'

alias lg="lazygit"

alias ld="lazydocker"

cnvm() {
  local path="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
  local current
  current=$(cat "$path")
  local new=$((1 - current))
  sudo sh -c "echo $new > $path"

  local old_state
  local new_state

  old_state=$([ "$current" -eq 1 ] && echo "on" || echo "off")
  new_state=$([ "$new" -eq 1 ] && echo "on" || echo "off")

  echo "Conservation mode: $old_state → $new_state"
}

alias kc="kimi-cli --yolo"

oc() {
  if [ "$#" -eq 0 ]; then
    local port
    port=$(shuf -i 49152-65535 -n 1)

    OPENCODE_PORT="$port" opencode --port "$port"
  else
    opencode "$@"
  fi
}
