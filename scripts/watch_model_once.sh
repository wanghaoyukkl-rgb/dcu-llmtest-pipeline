#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  watch_model_once.sh <serve|accuracy> <task_id> <run_dir_host> <container_name> <port> [framework]

Rules:
  - One-shot observer only: print current service/eval signals and exit.
  - Do not write state files, do not copy files from containers, do not run in a loop.
  - Read only host-mounted logs under <run_dir_host>.
  - Every log tail is limited to the last 10 lines.
USAGE
}

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
  usage
  exit 2
fi

PHASE=$1
TASK_ID=$2
RUN_DIR_HOST=$3
CONTAINER_NAME=$4
PORT=$5
FRAMEWORK=${6:-vllm}

case "${PHASE}" in
  serve|accuracy) ;;
  *)
    echo "[ERROR] phase must be serve or accuracy: ${PHASE}" >&2
    exit 2
    ;;
esac

if [ -z "${TASK_ID}" ] || [ -z "${RUN_DIR_HOST}" ] || [ -z "${PORT}" ]; then
  echo "[ERROR] task_id, run_dir_host and port must be non-empty" >&2
  exit 2
fi

SERVE_LOG="${RUN_DIR_HOST}/serve_logs/${TASK_ID}.serve.log"
OC_DIR="${RUN_DIR_HOST}/${TASK_ID}/opencompass"

print_header() {
  printf '\n== %s ==\n' "$1"
}

tail_file() {
  file=$1
  label=$2
  print_header "${label}: ${file}"
  if [ -f "${file}" ]; then
    tail -n 10 "${file}" || true
  else
    echo "[MISSING] ${file}"
  fi
}

tail_dir_logs() {
  dir=$1
  label=$2
  print_header "${label}: ${dir}"
  if [ ! -d "${dir}" ]; then
    echo "[MISSING] ${dir}"
    return 0
  fi

  found=0
  while IFS= read -r file; do
    found=1
    tail_file "${file}" "${label}"
  done < <(
    find "${dir}" -type f \
      \( -name '*.log' -o -name '*.out' -o -name '*.err' -o -name '*.txt' \) \
      2>/dev/null | sort
  )

  if [ "${found}" -eq 0 ]; then
    echo "[EMPTY] no log-like files under ${dir}"
  fi
}

tail_summary() {
  summary_dir=$1
  print_header "opencompass summary: ${summary_dir}"
  if [ ! -d "${summary_dir}" ]; then
    echo "[MISSING] ${summary_dir}"
    return 0
  fi

  found=0
  while IFS= read -r file; do
    found=1
    tail_file "${file}" "summary"
  done < <(
    find "${summary_dir}" -type f \
      \( -name '*.md' -o -name '*.csv' -o -name '*.json' -o -name '*.txt' \) \
      2>/dev/null | sort
  )

  if [ "${found}" -eq 0 ]; then
    echo "[EMPTY] no summary files under ${summary_dir}"
  fi
}

health_paths_for_framework() {
  case "${FRAMEWORK}" in
    sglang|SGLang)
      printf '%s\n' /health /get_server_info /v1/models /server_info
      ;;
    *)
      printf '%s\n' /health /v1/models /server_info /get_server_info
      ;;
  esac
}

check_health() {
  print_header "service health: 127.0.0.1:${PORT}"
  if ! command -v curl >/dev/null 2>&1; then
    echo "[UNKNOWN] curl not found"
    return 3
  fi

  while IFS= read -r path; do
    url="http://127.0.0.1:${PORT}${path}"
    if response=$(curl -fsS --max-time 5 "${url}" 2>&1); then
      echo "[READY] ${url}"
      printf '%s\n' "${response}" | tail -n 10 || true
      return 0
    fi
    err=$(printf '%s\n' "${response}" | tail -n 1 || true)
    echo "[NOT_READY] ${url} ${err}"
  done < <(health_paths_for_framework)

  return 3
}

print_header "watch_model_once"
echo "phase=${PHASE}"
echo "task_id=${TASK_ID}"
echo "run_dir=${RUN_DIR_HOST}"
echo "container=${CONTAINER_NAME}"
echo "framework=${FRAMEWORK}"
echo "port=${PORT}"
echo "timestamp=$(date '+%Y-%m-%d %H:%M:%S')"

case "${PHASE}" in
  serve)
    tail_file "${SERVE_LOG}" "serve log"
    check_health
    ;;
  accuracy)
    tail_dir_logs "${OC_DIR}/logs/infer" "opencompass logs/infer"
    tail_dir_logs "${OC_DIR}/logs/eval" "opencompass logs/eval"
    if [ -d "${OC_DIR}/summary" ]; then
      tail_summary "${OC_DIR}/summary"
    fi
    check_health
    ;;
esac
