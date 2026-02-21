#!/bin/bash

# Minimal TUI: prompt at bottom, scrolling output above
# Pure terminal escape sequences — no dependencies

PAD=1                                    # empty lines below prompt

setup() {
  printf '\033[?1049h'                     # alternate screen buffer
  rows=$(tput lines)
  cols=$(tput cols)
  prompt_row=$((rows - PAD))
  sep_row=$((prompt_row - 1))
  printf '\033[1;%dr' "$((sep_row - 1))"  # scroll region: line 1 to above separator
  draw_sep
  trap cleanup EXIT
  trap on_resize WINCH
}

cleanup() {
  printf '\033[r'                        # reset scroll region
  printf '\033[?1049l'                   # restore normal screen
}

resized=0
on_resize() {
  rows=$(tput lines)
  cols=$(tput cols)
  prompt_row=$((rows - PAD))
  sep_row=$((prompt_row - 1))
  printf '\033[2J'                         # clear entire screen
  printf '\033[1;%dr' "$((sep_row - 1))"   # new scroll region
  draw_sep
  resized=1
}

draw_sep() {
  printf '\033[%d;1H\033[K' "$sep_row"
  printf '\033[38;2;100;100;100m%*s\033[0m' "$cols" '' | tr ' ' '─'
}

setup

while true; do
  resized=0
  printf '\033[%d;1H\033[K' "$prompt_row"  # clear input line
  read -e -p "> " cmd
  rc=$?
  if ((resized)); then continue; fi        # WINCH interrupted read — just re-prompt
  ((rc != 0)) && break                     # actual EOF (Ctrl+D)
  [[ -z "$cmd" ]] && continue
  [[ "$cmd" == "exit" || "$cmd" == "quit" ]] && break
  history -s "$cmd"

  # move cursor into scroll region and let output stream naturally
  printf '\033[%d;1H\n' "$((sep_row - 1))"
  sh -c "$cmd" 2>&1
  # redraw separator (output may have overwritten it)
  draw_sep
done
