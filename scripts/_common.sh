#!/usr/bin/env bash
# OIH Bio Tools — shared helpers for all tool runner scripts.
# Source this file: source "${KIMI_SKILL_DIR}/../../../scripts/_common.sh"

# Prevent Git Bash (MSYS) from rewriting container paths/args as Windows paths.
export MSYS2_ARG_CONV_EXCL='*'

: "${OIH_HOME:=E:/oih}"
: "${OIH_DATA:=$OIH_HOME/data}"
: "${OIH_MODELS:=$OIH_HOME/models}"
: "${OIH_COMPOSE:=$OIH_HOME/oih-platform/docker-compose.windows.yml}"

# Translate a host (Windows/POSIX) path under $OIH_DATA to the in-container path.
oih_container_path() {
  local p="$1"
  p="${p//\\//}"                       # backslashes -> slashes
  local d="${OIH_DATA//\\//}"
  d="${d/#e:/E:}"                      # normalize drive letter case
  p="${p/#e:/E:}"
  if [[ "$p" == "$d/"* ]]; then
    echo "/data/oih/${p#$d/}"
  else
    echo "$p"
  fi
}

# Ensure a named container is running; start the whole stack if absent.
oih_ensure_container() {
  local name="$1"
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$name"; then
    return 0
  fi
  echo "[oih] container $name not running; starting via compose..." >&2
  docker compose -f "$OIH_COMPOSE" up -d "$name" >&2 || {
    echo "[oih] ERROR: failed to start $name. Is Docker Desktop running and the image built?" >&2
    return 1
  }
  sleep 3
}

# docker exec with correct env for compute tools (GPU pool pick by host nvidia-smi).
oih_exec() {
  local name="$1"; shift
  oih_ensure_container "$name" || return 1
  local gpu=""
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=index,memory.used --format=csv,noheader,nounits \
          | sort -t, -k2 -n | head -1 | cut -d, -f1 | tr -d ' ')
  fi
  if [ -n "$gpu" ]; then
    docker exec -e "CUDA_VISIBLE_DEVICES=$gpu" "$name" "$@"
  else
    docker exec "$name" "$@"
  fi
}

# Print a JSON-ish status for the agent.
oih_ok() { echo "OIH_STATUS: OK"; }
oih_fail() { echo "OIH_STATUS: FAIL $*"; }
