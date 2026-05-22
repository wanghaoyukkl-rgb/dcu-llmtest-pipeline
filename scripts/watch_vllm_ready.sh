#!/bin/bash
# Backward-compatible vLLM entrypoint.
# The implementation is intentionally generic enough for vLLM, SGLang, and
# OpenAI-compatible backends. New flows should prefer watch_llm_ready.sh.
#
# Usage:
#   bash watch_vllm_ready.sh <container_name> [log_file] [status_file] [port]
#
# Example:
#   nohup bash /tmp/watch_vllm_ready.sh dcu-qwen /tmp/vllm_serve.log /tmp/vllm_status.json 8000 \
#     > /tmp/watch_vllm_ready.monitor.log 2>&1 &

set -u

CONTAINER_NAME=${1:-""}
LOG_FILE=${2:-"/tmp/vllm_serve.log"}
STATUS_FILE=${3:-"/tmp/llm_status.json"}
PORT=${4:-"8000"}
SERVICE_NAME=${5:-"vllm"}
HEALTH_PATHS=${6:-"/health,/v1/models,/server_info,/get_server_info"}
CHECK_INTERVAL=${CHECK_INTERVAL:-5}
MAX_WAIT_SECONDS=${MAX_WAIT_SECONDS:-1800}
LAST_OFFSET=0
START_TS=$(date +%s)
LAST_READY_ENDPOINT=""

json_escape() {
    sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | cut -c 1-1200
}

write_status() {
    local status=$1
    local message=$2
    local detail=$3
    local escaped_detail
    escaped_detail=$(printf '%s' "${detail}" | json_escape)

    cat > "${STATUS_FILE}" <<EOF
{
  "status": "${status}",
  "message": "${message}",
  "last_check": "$(date '+%Y-%m-%d %H:%M:%S')",
  "service": "${SERVICE_NAME}",
  "container": "${CONTAINER_NAME}",
  "port": "${PORT}",
  "ready_endpoint": "${LAST_READY_ENDPOINT}",
  "health_paths": "${HEALTH_PATHS}",
  "log_file": "${LOG_FILE}",
  "detail": "${escaped_detail}"
}
EOF
}

http_ready_with_curl() {
    local path=$1
    local code
    code=$(curl -o /dev/null -sS -w "%{http_code}" --max-time 2 "http://127.0.0.1:${PORT}${path}" 2>/dev/null || true)
    case "${code}" in
        2*|3*) return 0 ;;
        *) return 1 ;;
    esac
}

http_ready_with_python() {
    local path=$1
    python3 - "${PORT}" "${path}" >/dev/null 2>&1 <<'PY'
import sys
import urllib.request

port, path = sys.argv[1], sys.argv[2]
try:
    with urllib.request.urlopen(f"http://127.0.0.1:{port}{path}", timeout=2) as resp:
        sys.exit(0 if 200 <= resp.status < 400 else 1)
except Exception:
    sys.exit(1)
PY
}

health_ready() {
    local old_ifs=${IFS}
    local path
    IFS=','
    for path in ${HEALTH_PATHS}; do
        IFS=${old_ifs}
        path=$(printf '%s' "${path}" | sed 's/^ *//; s/ *$//')
        [ -z "${path}" ] && continue

        if command -v curl >/dev/null 2>&1; then
            if http_ready_with_curl "${path}"; then
                LAST_READY_ENDPOINT="http://127.0.0.1:${PORT}${path}"
                return 0
            fi
        elif command -v python3 >/dev/null 2>&1; then
            if http_ready_with_python "${path}"; then
                LAST_READY_ENDPOINT="http://127.0.0.1:${PORT}${path}"
                return 0
            fi
        fi
        IFS=','
    done
    IFS=${old_ifs}
    return 1
}

if [ -z "${CONTAINER_NAME}" ]; then
    write_status "error" "缺少 container_name 参数" ""
    exit 1
fi

write_status "starting" "等待 ${SERVICE_NAME} 服务启动" ""

while true; do
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TS))

    if [ "${ELAPSED}" -gt "${MAX_WAIT_SECONDS}" ]; then
        TAIL_LOG=$(docker exec "${CONTAINER_NAME}" tail -n 40 "${LOG_FILE}" 2>/dev/null || true)
        write_status "timeout" "超过 ${MAX_WAIT_SECONDS}s 未就绪" "${TAIL_LOG}"
        exit 2
    fi

    if health_ready; then
        write_status "ready" "${SERVICE_NAME} 服务已就绪" "health check passed"
        exit 0
    fi

    if docker exec "${CONTAINER_NAME}" test -f "${LOG_FILE}" >/dev/null 2>&1; then
        CUR_OFFSET=$(docker exec "${CONTAINER_NAME}" sh -c "wc -c < '${LOG_FILE}'" 2>/dev/null || echo 0)

        if [ "${CUR_OFFSET}" -gt "${LAST_OFFSET}" ]; then
            NEW_LOG=$(docker exec "${CONTAINER_NAME}" sh -c "tail -c +$((LAST_OFFSET + 1)) '${LOG_FILE}' | tail -n 80" 2>/dev/null || true)
            LAST_OFFSET=${CUR_OFFSET}

            if echo "${NEW_LOG}" | grep -qiE "Traceback|OOM|OutOfMemory|HIP error|CUDA error|Killed|RuntimeError|Exception|No such file|ModuleNotFoundError|Address already in use|Fatal|Aborted"; then
                write_status "error" "启动日志中检测到错误" "${NEW_LOG}"
                exit 1
            fi

            if echo "${NEW_LOG}" | grep -qiE "Application startup complete|Uvicorn running|Started server process|server is fired up|ready to roll|server started|listening on"; then
                write_status "almost_ready" "日志显示服务接近就绪，等待 HTTP 探活确认" ""
            else
                SNAPSHOT=$(echo "${NEW_LOG}" | tail -n 5)
                write_status "starting" "服务仍在启动" "${SNAPSHOT}"
            fi
        fi
    else
        write_status "starting" "日志文件尚未生成" ""
    fi

    sleep "${CHECK_INTERVAL}"
done
