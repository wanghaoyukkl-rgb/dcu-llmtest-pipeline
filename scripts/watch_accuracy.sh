#!/bin/bash
# 精度测试后台监控脚本
# 在宿主机上通过 nohup 运行，不依赖 Claude/Codex session 保持连接。
# 优先读取评测日志判断进度；可选扫描 prediction 文件，每个模型只检查一次前 3 条样本；
# 若 3 条样本均疑似乱码，
# 则中断当前评测/服务进程以释放加速卡资源，但保留容器。
#
# 用法（宿主机执行）：
#   nohup bash watch_accuracy.sh <log_file> <status_file> [prediction_path] [container_name] [check_interval] [prediction_check_delay] &
#
# 参数：
#   log_file        容器内或宿主机上的评测日志路径，例如 /tmp/eval_accuracy.log
#   status_file     宿主机状态文件，例如 /tmp/eval_status.json
#   prediction_path 可选，prediction 文件或目录；传 auto 时在容器内自动查找近期 prediction/jsonl 文件
#   container_name  可选；提供后通过 docker exec 读取容器内日志并可在乱码时释放资源
#   check_interval  可选，默认 120 秒
#   prediction_check_delay 可选，默认 600 秒；到点后读取一次前 3 条 prediction
#
# 状态文件格式（JSON，Agent 可直接读取）：
#   {"status": "running|done|error|aborted", "progress": "...", "last_check": "...", "result": "..."}

LOG_FILE=${1:-"/tmp/eval_accuracy.log"}
STATUS_FILE=${2:-"/tmp/eval_status.json"}
PREDICTION_PATH=${3:-""}
CONTAINER_NAME=${4:-""}
CHECK_INTERVAL=${5:-120}
PREDICTION_CHECK_DELAY=${6:-600}
PREDICTION_CHECKED=0
START_TS=$(date +%s)

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' '
}

write_status() {
    local status
    local progress
    local result
    status=$(json_escape "$1")
    progress=$(json_escape "$2")
    result=$(json_escape "$3")
    cat > "${STATUS_FILE}" <<EOF
{
  "status": "${status}",
  "progress": "${progress}",
  "last_check": "$(date '+%Y-%m-%d %H:%M:%S')",
  "result": "${result}",
  "log_file": "${LOG_FILE}",
  "prediction_path": "${PREDICTION_PATH}",
  "container": "${CONTAINER_NAME}"
}
EOF
}

in_container() {
    [ -n "${CONTAINER_NAME}" ]
}

log_exists() {
    if in_container; then
        docker exec "${CONTAINER_NAME}" test -f "${LOG_FILE}" >/dev/null 2>&1
    else
        test -f "${LOG_FILE}"
    fi
}

tail_log() {
    if in_container; then
        docker exec "${CONTAINER_NAME}" tail -n 120 "${LOG_FILE}" 2>/dev/null
    else
        tail -n 120 "${LOG_FILE}" 2>/dev/null
    fi
}

count_log_lines() {
    if in_container; then
        docker exec "${CONTAINER_NAME}" sh -c "wc -l < '${LOG_FILE}'" 2>/dev/null
    else
        wc -l < "${LOG_FILE}" 2>/dev/null
    fi
}

release_accelerator_resources() {
    if ! in_container; then
        return 0
    fi
    docker exec "${CONTAINER_NAME}" bash -lc \
      "pkill -f 'evalscope|opencompass|vllm serve|sglang.launch_server|sglang' || true" \
      >/dev/null 2>&1
}

detect_garbled_predictions_host() {
    local path=$1
    python3 - "$path" <<'PY'
import json
import os
import re
import sys

root = sys.argv[1]

def resolve(path):
    if not path or path == "auto":
        candidates = []
        for base in ("/tmp", "/workspace", "/mnt"):
            if not os.path.isdir(base):
                continue
            for dirpath, _, filenames in os.walk(base):
                for name in filenames:
                    lname = name.lower()
                    if "pred" in lname or lname.endswith(".jsonl") or lname.endswith(".json"):
                        full = os.path.join(dirpath, name)
                        try:
                            candidates.append((os.path.getmtime(full), full))
                        except OSError:
                            pass
        return max(candidates)[1] if candidates else ""
    if os.path.isdir(path):
        candidates = []
        for dirpath, _, filenames in os.walk(path):
            for name in filenames:
                lname = name.lower()
                if "pred" in lname or lname.endswith(".jsonl") or lname.endswith(".json"):
                    full = os.path.join(dirpath, name)
                    try:
                        candidates.append((os.path.getmtime(full), full))
                    except OSError:
                        pass
        return max(candidates)[1] if candidates else ""
    return path if os.path.isfile(path) else ""

def extract_text(obj):
    if isinstance(obj, str):
        return obj
    if not isinstance(obj, dict):
        return ""
    for key in ("prediction", "pred", "response", "output", "text", "generated_text", "completion"):
        val = obj.get(key)
        if isinstance(val, str):
            return val
        if isinstance(val, list):
            return " ".join(str(x) for x in val)
    choices = obj.get("choices")
    if isinstance(choices, list) and choices:
        return extract_text(choices[0])
    return ""

def garbled(text):
    s = str(text).strip()
    if not s:
        return False
    if "\ufffd" in s or "\\ufffd" in s:
        return True
    if re.search(r"([\W_])\1{7,}", s):
        return True
    if len(s) >= 12:
        useful = sum(ch.isalnum() or "\u4e00" <= ch <= "\u9fff" or ch in " .,;:!?+-=*/()[]{}<>%$#@'\"\n\t" for ch in s)
        if useful / max(len(s), 1) < 0.35:
            return True
    return False

file_path = resolve(root)
if not file_path:
    print("NO_PREDICTION_FILE")
    sys.exit(0)

checked = 0
garbled_count = 0
with open(file_path, "r", encoding="utf-8", errors="replace") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            obj = line
        text = extract_text(obj)
        if not text:
            continue
        checked += 1
        if garbled(text):
            garbled_count += 1
        if checked >= 3:
            break

if checked >= 3:
    if garbled_count == 3:
        print(f"GARBLED:{file_path}:前 3 条 prediction 均疑似乱码")
        sys.exit(10)
    print(f"OK:{file_path}:已检查前 3 条 prediction，疑似乱码 {garbled_count} 条")
else:
    print(f"WAIT:{file_path}:prediction 样本不足 3 条")
sys.exit(0)
PY
}

detect_garbled_predictions_container() {
    local path=$1
    docker exec "${CONTAINER_NAME}" python3 - "$path" <<'PY'
import json
import os
import re
import sys

root = sys.argv[1]

def resolve(path):
    if not path or path == "auto":
        candidates = []
        for base in ("/tmp", "/workspace", "/mnt"):
            if not os.path.isdir(base):
                continue
            for dirpath, _, filenames in os.walk(base):
                for name in filenames:
                    lname = name.lower()
                    if "pred" in lname or lname.endswith(".jsonl") or lname.endswith(".json"):
                        full = os.path.join(dirpath, name)
                        try:
                            candidates.append((os.path.getmtime(full), full))
                        except OSError:
                            pass
        return max(candidates)[1] if candidates else ""
    if os.path.isdir(path):
        candidates = []
        for dirpath, _, filenames in os.walk(path):
            for name in filenames:
                lname = name.lower()
                if "pred" in lname or lname.endswith(".jsonl") or lname.endswith(".json"):
                    full = os.path.join(dirpath, name)
                    try:
                        candidates.append((os.path.getmtime(full), full))
                    except OSError:
                        pass
        return max(candidates)[1] if candidates else ""
    return path if os.path.isfile(path) else ""

def extract_text(obj):
    if isinstance(obj, str):
        return obj
    if not isinstance(obj, dict):
        return ""
    for key in ("prediction", "pred", "response", "output", "text", "generated_text", "completion"):
        val = obj.get(key)
        if isinstance(val, str):
            return val
        if isinstance(val, list):
            return " ".join(str(x) for x in val)
    choices = obj.get("choices")
    if isinstance(choices, list) and choices:
        return extract_text(choices[0])
    return ""

def garbled(text):
    s = str(text).strip()
    if not s:
        return False
    if "\ufffd" in s or "\\ufffd" in s:
        return True
    if re.search(r"([\W_])\1{7,}", s):
        return True
    if len(s) >= 12:
        useful = sum(ch.isalnum() or "\u4e00" <= ch <= "\u9fff" or ch in " .,;:!?+-=*/()[]{}<>%$#@'\"\n\t" for ch in s)
        if useful / max(len(s), 1) < 0.35:
            return True
    return False

file_path = resolve(root)
if not file_path:
    print("NO_PREDICTION_FILE")
    sys.exit(0)

checked = 0
garbled_count = 0
with open(file_path, "r", encoding="utf-8", errors="replace") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            obj = line
        text = extract_text(obj)
        if not text:
            continue
        checked += 1
        if garbled(text):
            garbled_count += 1
        if checked >= 3:
            break

if checked >= 3:
    if garbled_count == 3:
        print(f"GARBLED:{file_path}:前 3 条 prediction 均疑似乱码")
        sys.exit(10)
    print(f"OK:{file_path}:已检查前 3 条 prediction，疑似乱码 {garbled_count} 条")
else:
    print(f"WAIT:{file_path}:prediction 样本不足 3 条")
sys.exit(0)
PY
}

write_status "running" "监控启动，等待评测日志..." ""

while true; do
    if ! log_exists; then
        write_status "running" "评测日志尚未生成，等待任务启动..." ""
        sleep "${CHECK_INTERVAL}"
        continue
    fi

    LAST_LINES=$(tail_log)
    TOTAL_LINES=$(count_log_lines)

    NOW_TS=$(date +%s)
    if [ -n "${PREDICTION_PATH}" ] && [ "${PREDICTION_CHECKED}" -eq 0 ] && [ $((NOW_TS - START_TS)) -ge "${PREDICTION_CHECK_DELAY}" ]; then
        if in_container; then
            PRED_CHECK=$(detect_garbled_predictions_container "${PREDICTION_PATH}")
        else
            PRED_CHECK=$(detect_garbled_predictions_host "${PREDICTION_PATH}")
        fi
        PRED_CODE=$?
        if [ "${PRED_CODE}" -eq 10 ]; then
            release_accelerator_resources
            write_status "aborted" "prediction 前 3 条均疑似乱码，已中断当前评测并尝试释放加速卡资源；容器保留。" "${PRED_CHECK}"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 监控：${PRED_CHECK}"
            exit 10
        fi
        case "${PRED_CHECK}" in
            OK:*)
                PREDICTION_CHECKED=1
                ;;
        esac
    fi

    if echo "${LAST_LINES}" | grep -qiE "(error|traceback|exception|failed|killed|KeyError|BuilderConfig)"; then
        ERR_LINE=$(echo "${LAST_LINES}" | grep -iE "(error|traceback|exception|failed|killed|KeyError|BuilderConfig)" | tail -6)
        release_accelerator_resources
        write_status "error" "检测到错误（第 ${TOTAL_LINES} 行），已尝试释放当前评测/服务进程；容器保留。" "${ERR_LINE}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 监控：发现错误，已尝试释放资源并退出监控。"
        exit 1
    fi

    if echo "${LAST_LINES}" | grep -qiE "(accuracy|pass@|score|result|测试完成|完成)"; then
        RESULT_LINE=$(echo "${LAST_LINES}" | grep -iE "(accuracy|pass@|score|result)" | tail -8)
        write_status "done" "测试已完成（共 ${TOTAL_LINES} 行日志）" "${RESULT_LINE}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 监控：测试完成，退出监控。"
        exit 0
    fi

    PROGRESS=$(echo "${LAST_LINES}" | tail -5 | tr '\n' ' ')
    write_status "running" "${PROGRESS}（共 ${TOTAL_LINES} 行）" ""

    sleep "${CHECK_INTERVAL}"
done
