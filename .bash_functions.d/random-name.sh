random_name () {
  local type="${1:-animal}"

  local animals=(
    cat dog fox wolf bear lion tiger rabbit deer owl
    eagle shark dolphin horse mouse
  )

  local colors=(
    red blue green yellow purple orange pink black white gray
    cyan magenta teal lime brown indigo
  )

  local firstnames=(
    alex emma john olivia michael sophia david isabella james mia
    daniel ava benjamin lucas chloe
  )

  local adjectives=(
    fast slow clever brave quiet loud happy sad fuzzy shiny
    bright dark tiny huge wild
  )

  local arr

  case "$type" in
    animal) arr=("${animals[@]}") ;;
    color) arr=("${colors[@]}") ;;
    firstname) arr=("${firstnames[@]}") ;;
    adjective) arr=("${adjectives[@]}") ;;
    *) arr=("${animals[@]}") ;;  # default fallback
  esac
  [[ ${#arr[@]} -eq 0 ]] && { echo "error"; return 1; }
  echo "${arr[$RANDOM % ${#arr[@]}]}"
}
