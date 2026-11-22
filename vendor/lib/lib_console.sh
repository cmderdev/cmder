debug_output() {
  if [ "${debug_output:-0}" -gt 0 ]; then
    printf '%s DEBUG(%s): %s\n\n' "$(date '+%H:%M:%S')" "$1" "$2" >&2
  fi
}
