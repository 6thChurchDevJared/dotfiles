#!/usr/bin/env bash
# __NAME__ - one line on what this does.
#
# Usage: __NAME__ [-h] ARG
#
# Longer notes: inputs, outputs, side effects, anything surprising.
set -euo pipefail

usage() { sed -n '2,/^set /{/^set /d;s/^# \{0,1\}//;p;}' "$0"; }
die() {
  printf '%s: %s\n' "${0##*/}" "$*" >&2
  exit 1
}

main() {
  case "${1:-}" in
    -h | --help)
      usage
      exit 0
      ;;
    "")
      usage >&2
      exit 2
      ;;
  esac
  local arg="$1"
  printf 'hello from %s with %s\n' "${0##*/}" "$arg"
}

main "$@"
