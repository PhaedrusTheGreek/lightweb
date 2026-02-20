#!/bin/bash

# Funny social media notifications with colorful terminal animations

NOTIFICATIONS=(
  "Your ex just liked your photo from 2019... at 3:47 AM"
  "Someone screenshotted your LinkedIn crying selfie"
  "Elon just mass-renamed Twitter to Y... wait, no, back to X... no, it's Z now"
  "Your mom commented 'WHO IS THIS WOMAN???' on your profile pic"
  "Mark Zuckerberg challenged you to a cage match in the Metaverse"
  "Your boss just followed your finsta"
  "A stranger on Reddit gave your hot take 47 awards"
  "Your grandma went viral for roasting a tech bro on TikTok"
  "Someone replied 'ratio' to your heartfelt eulogy post"
  "Your cat's Instagram now has more followers than you"
  "Jeff Bezos liked your tweet about being broke"
  "You've been tagged in a photo you explicitly asked to be deleted"
  "Your 'typing...' bubble has been visible for 45 minutes"
  "A LinkedIn influencer reposted your grocery list as productivity advice"
  "Your Spotify Wrapped revealed you listened to Baby Shark 312 times"
  "An AI chatbot just unfollowed you"
  "Your Discord server has achieved sentience and is demanding PTO"
  "Someone just replied 'k' to your 4-paragraph text"
  "A TikTok psychic predicted your next embarrassing tweet"
  "Your tweet from 2014 just got subpoenaed"
  "YouTube recommended your own cringe video from middle school"
  "Instagram suggested your therapist as someone you may know"
  "Your Slack status has been 'In a meeting' for 3 days straight"
  "A Facebook Marketplace bot just lowballed your self-worth"
  "Your BeReal went off during an ugly cry in the bathroom"
  "Someone started a GoFundMe for your dating life"
  "Your Google review of a Wendy's went viral in Japan"
  "A parody account of you just got verified before you did"
  "Duolingo owl reported you to Interpol for missing Spanish lessons"
  "Your Venmo payment description 'for the bodies' is trending"
)

# Print a single character with an RGB color
print_rgb() {
  local r=$1 g=$2 b=$3 char="$4"
  printf "\033[38;2;%d;%d;%dm%s\033[0m" "$r" "$g" "$b" "$char"
}

# Gradient text: interpolate between two RGB colors across a string
print_gradient() {
  local text="$1"
  local r1=$2 g1=$3 b1=$4  # start color
  local r2=$5 g2=$6 b2=$7  # end color
  local len=${#text}

  for ((i = 0; i < len; i++)); do
    if ((len > 1)); then
      local t=$((i * 1000 / (len - 1)))
    else
      local t=0
    fi
    local r=$(( r1 + (r2 - r1) * t / 1000 ))
    local g=$(( g1 + (g2 - g1) * t / 1000 ))
    local b=$(( b1 + (b2 - b1) * t / 1000 ))
    print_rgb "$r" "$g" "$b" "${text:$i:1}"
  done
}

# Rainbow gradient across a string
print_rainbow() {
  local text="$1"
  local len=${#text}
  local offset=${2:-0}

  for ((i = 0; i < len; i++)); do
    local hue=$(( ((i + offset) * 360 / len) % 360 ))
    # HSV to RGB (s=1, v=1)
    local hi=$(( hue / 60 % 6 ))
    local f=$(( hue % 60 ))
    local q=$(( 255 - 255 * f / 60 ))
    local t=$(( 255 * f / 60 ))
    local r g b
    case $hi in
      0) r=255; g=$t;   b=0   ;;
      1) r=$q;  g=255;  b=0   ;;
      2) r=0;   g=255;  b=$t  ;;
      3) r=0;   g=$q;   b=255 ;;
      4) r=$t;  g=0;    b=255 ;;
      5) r=255; g=0;    b=$q  ;;
    esac
    print_rgb "$r" "$g" "$b" "${text:$i:1}"
  done
}

# Sparkle animation: reveal text character by character with sparkle effect
sparkle_reveal() {
  local text="$1"
  local r1=$2 g1=$3 b1=$4
  local r2=$5 g2=$6 b2=$7
  local len=${#text}
  local sparkles=("✦" "✧" "⟡" "◆" "⋆" "★")

  for ((i = 0; i <= len; i++)); do
    printf "\r"
    # Print already-revealed text in gradient
    for ((j = 0; j < i; j++)); do
      if ((len > 1)); then
        local t=$((j * 1000 / (len - 1)))
      else
        local t=0
      fi
      local r=$(( r1 + (r2 - r1) * t / 1000 ))
      local g=$(( g1 + (g2 - g1) * t / 1000 ))
      local b=$(( b1 + (b2 - b1) * t / 1000 ))
      print_rgb "$r" "$g" "$b" "${text:$j:1}"
    done
    # Print sparkle cursor
    if ((i < len)); then
      local si=$(( RANDOM % ${#sparkles[@]} ))
      print_rgb 255 255 100 "${sparkles[$si]}"
      printf "  "
    fi
    sleep 0.012
  done
}

# Wave animation: text ripples with shifting rainbow
wave_animate() {
  local text="$1"
  local frames=25
  local len=${#text}

  for ((frame = 0; frame < frames; frame++)); do
    printf "\r"
    for ((i = 0; i < len; i++)); do
      local hue=$(( ((i * 8 + frame * 15) * 360 / 200) % 360 ))
      local hi=$(( hue / 60 % 6 ))
      local f=$(( hue % 60 ))
      local q=$(( 255 - 255 * f / 60 ))
      local t=$(( 255 * f / 60 ))
      local r g b
      case $hi in
        0) r=255; g=$t;   b=0   ;;
        1) r=$q;  g=255;  b=0   ;;
        2) r=0;   g=255;  b=$t  ;;
        3) r=0;   g=$q;   b=255 ;;
        4) r=$t;  g=0;    b=255 ;;
        5) r=255; g=0;    b=$q  ;;
      esac
      # Vertical wave offset using bold toggle
      local wave_y=$(( (i + frame) % 6 ))
      if ((wave_y < 3)); then
        printf "\033[1m"
      fi
      print_rgb "$r" "$g" "$b" "${text:$i:1}"
      printf "\033[0m"
    done
    sleep 0.06
  done
}

# Neon pulse: text throbs between dim and bright
neon_pulse() {
  local text="$1"
  local r=$2 g=$3 b=$4
  local pulses=8

  for ((p = 0; p < pulses; p++)); do
    # Bright phase
    printf "\r\033[1m"
    print_gradient "$text" "$r" "$g" "$b" 255 255 255
    printf "\033[0m"
    sleep 0.1
    # Dim phase
    printf "\r"
    print_gradient "$text" $(( r/3 )) $(( g/3 )) $(( b/3 )) $(( r/2 )) $(( g/2 )) $(( b/2 ))
    sleep 0.1
  done
  # Final bright
  printf "\r\033[1m"
  print_gradient "$text" "$r" "$g" "$b" 255 255 255
  printf "\033[0m"
}

# Typewriter effect with color
typewriter() {
  local text="$1"
  local r1=$2 g1=$3 b1=$4
  local r2=$5 g2=$6 b2=$7
  local len=${#text}

  for ((i = 0; i < len; i++)); do
    if ((len > 1)); then
      local t=$((i * 1000 / (len - 1)))
    else
      local t=0
    fi
    local r=$(( r1 + (r2 - r1) * t / 1000 ))
    local g=$(( g1 + (g2 - g1) * t / 1000 ))
    local b=$(( b1 + (b2 - b1) * t / 1000 ))
    print_rgb "$r" "$g" "$b" "${text:$i:1}"
    sleep 0.02
  done
}

# Glitch effect: scramble then resolve
glitch_reveal() {
  local text="$1"
  local r1=$2 g1=$3 b1=$4
  local r2=$5 g2=$6 b2=$7
  local len=${#text}
  local glitch_chars="!@#$%^&*<>{}[]|/~"
  local passes=10

  for ((pass = 0; pass < passes; pass++)); do
    printf "\r"
    local resolve_ratio=$(( pass * len / passes ))
    for ((i = 0; i < len; i++)); do
      if ((len > 1)); then
        local t=$((i * 1000 / (len - 1)))
      else
        local t=0
      fi
      local r=$(( r1 + (r2 - r1) * t / 1000 ))
      local g=$(( g1 + (g2 - g1) * t / 1000 ))
      local b=$(( b1 + (b2 - b1) * t / 1000 ))
      if ((i < resolve_ratio)); then
        print_rgb "$r" "$g" "$b" "${text:$i:1}"
      else
        local gi=$(( RANDOM % ${#glitch_chars} ))
        print_rgb $(( RANDOM % 256 )) $(( RANDOM % 256 )) $(( RANDOM % 256 )) "${glitch_chars:$gi:1}"
      fi
    done
    sleep 0.08
  done
  # Final clean render
  printf "\r"
  print_gradient "$text" "$r1" "$g1" "$b1" "$r2" "$g2" "$b2"
}

# Color palettes: [r1, g1, b1, r2, g2, b2]
PALETTES=(
  "255 50 150 50 200 255"    # Pink → Cyan
  "255 100 0 255 255 0"      # Orange → Yellow
  "0 255 150 100 0 255"      # Mint → Purple
  "255 0 100 255 200 0"      # Magenta → Gold
  "0 200 255 255 0 200"      # Sky → Pink
  "150 255 0 0 150 255"      # Lime → Blue
  "255 0 0 0 0 255"          # Red → Blue
  "255 150 0 0 255 150"      # Amber → Seafoam
  "200 0 255 0 255 200"      # Violet → Aqua
  "255 200 50 50 255 200"    # Sunshine → Teal
)

ANIMATION_TYPES=("sparkle" "wave" "neon" "typewriter" "glitch" "rainbow")

clear
printf "\n"
print_gradient "  ╔══════════════════════════════════════════════════════════════╗" 100 100 255 255 100 255
printf "\n"
print_gradient "  ║       🔔  TOTALLY REAL SOCIAL MEDIA NOTIFICATIONS  🔔       ║" 255 200 50 255 50 200
printf "\n"
print_gradient "  ╚══════════════════════════════════════════════════════════════╝" 100 100 255 255 100 255
printf "\n\n"

idx=0
used_indices=()

while true; do
  # Pick a random notification we haven't used yet
  if (( ${#used_indices[@]} >= ${#NOTIFICATIONS[@]} )); then
    used_indices=()
  fi
  while true; do
    ni=$(( RANDOM % ${#NOTIFICATIONS[@]} ))
    already_used=0
    for u in "${used_indices[@]}"; do
      if ((u == ni)); then already_used=1; break; fi
    done
    if ((already_used == 0)); then
      used_indices+=("$ni")
      break
    fi
  done

  notification="${NOTIFICATIONS[$ni]}"
  palette_idx=$(( RANDOM % ${#PALETTES[@]} ))
  palette=(${PALETTES[$palette_idx]})
  anim_idx=$(( RANDOM % ${#ANIMATION_TYPES[@]} ))
  anim="${ANIMATION_TYPES[$anim_idx]}"

  # Prefix with timestamp and bell icon
  timestamp=$(date +"%H:%M:%S")
  printf "\033[38;2;100;100;100m[%s]\033[0m " "$timestamp"
  print_rgb 255 220 50 "🔔 "

  case $anim in
    sparkle)
      sparkle_reveal "$notification" ${palette[@]}
      ;;
    wave)
      wave_animate "$notification"
      ;;
    neon)
      neon_pulse "$notification" ${palette[0]} ${palette[1]} ${palette[2]}
      ;;
    typewriter)
      typewriter "$notification" ${palette[@]}
      ;;
    glitch)
      glitch_reveal "$notification" ${palette[@]}
      ;;
    rainbow)
      print_rainbow "$notification"
      ;;
  esac

  printf "\n"
  idx=$((idx + 1))
  sleep 5
done
