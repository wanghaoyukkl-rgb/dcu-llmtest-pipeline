#!/bin/bash
# 统一精度测试后台监控脚本
# 在宿主机上通过 nohup 运行，不依赖 Claude/Codex session 保持连接。
# evalscope 和 OpenCompass 都使用同一套状态写入逻辑。
# 可通过日志、done 文件、summary glob 或 completion 命令判断完成。
#
# 用法（宿主机执行）：
#   nohup bash watch_accuracy.sh <log_file> <status_file> [container_name] [check_interval] &
#
# 参数：
#   log_file        容器内或宿主机上的评测日志路径，例如 /tmp/eval_accuracy.log；无日志可传 none
#   status_file     宿主机状态文件，例如 /tmp/eval_status.json
#   container_name  可选；提供后通过 docker exec 读取容器内日志并可在错误时释放资源
#   check_interval  可选，默认 600 秒；长任务建议 1800 秒
#   报告字段可通过环境变量传入：
#     REPORT_FILE、TASK_ID、REPORT_MODEL、REPORT_DATASET、REPORT_NODE、REPORT_OUTPUT_DIR
#   计划表字段可通过环境变量传入：
#     PLAN_FILE、TEST_TOOL、ACCELERATOR
#   完成判断可通过环境变量传入：
#     COMPLETION_CHECK_CMD、DONE_FILE、SUMMARY_GLOB
#
# 状态文件格式（JSON，Agent 可直接读取）：
#   {"status": "running|done|error|aborted", "progress": "...", "last_check": "...", "result": "..."}

LOG_FILE=${1:-"/tmp/eval_accuracy.log"}
STATUS_FILE=${2:-"/tmp/eval_status.json"}

# 兼容旧参数格式：第三个旧参数会被忽略，第四个旧参数仍作为 container 使用。
if [ -n "${5:-}" ] || { [ -n "${4:-}" ] && ! printf '%s' "${4}" | grep -Eq '^[0-9]+$'; }; then
    CONTAINER_NAME=${4:-""}
    CHECK_INTERVAL=${5:-600}
else
    CONTAINER_NAME=${3:-""}
    CHECK_INTERVAL=${4:-600}
fi

REPORT_FILE=${REPORT_FILE:-"/tmp/test_report.md"}
PLAN_FILE=${PLAN_FILE:-"/tmp/task_plan.md"}
TASK_ID=${TASK_ID:-"accuracy"}
REPORT_MODEL=${REPORT_MODEL:-${MODEL_NAME:-""}}
REPORT_DATASET=${REPORT_DATASET:-${DATASET:-""}}
REPORT_NODE=${REPORT_NODE:-$(hostname 2>/dev/null || echo local)}
REPORT_OUTPUT_DIR=${REPORT_OUTPUT_DIR:-""}
TEST_TOOL=${TEST_TOOL:-${EVAL_TOOL:-"evalscope"}}
ACCELERATOR=${ACCELERATOR:-${CARD_TYPE:-""}}
COMPLETION_CHECK_CMD=${COMPLETION_CHECK_CMD:-""}
DONE_FILE=${DONE_FILE:-""}
SUMMARY_GLOB=${SUMMARY_GLOB:-""}
CURRENT_PLAN_STATUS=""

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' '
}

markdown_cell() {
    printf '%s' "$1" | tr '\n\r|' '  /' | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
}

write_report() {
    local status
    local progress
    local result
    local detail
    status=$(markdown_cell "$1")
    progress=$(markdown_cell "$2")
    result=$(markdown_cell "$3")
    if [ -n "${result}" ]; then
        detail="${result}"
    else
        detail="${progress}"
    fi
    mkdir -p "$(dirname "${REPORT_FILE}")" 2>/dev/null || true
    {
        echo "# DCU LLM 测试报告"
        echo
        echo "更新时间：$(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "| 任务ID | 模型 | 数据集 | 节点 | 状态 | 结果/进度 | 输出 |"
        echo "|---|---|---|---|---|---|---|"
        echo "| $(markdown_cell "${TASK_ID}") | $(markdown_cell "${REPORT_MODEL}") | $(markdown_cell "${REPORT_DATASET}") | $(markdown_cell "${REPORT_NODE}") | ${status:-running} | ${detail:-"-"} | $(markdown_cell "${REPORT_OUTPUT_DIR}") |"
        echo
        echo "说明：curl 样本检查在模型服务 ready 后执行；失败或乱码会释放该任务资源。"
    } > "${REPORT_FILE}"
}

plan_status_from_watcher() {
    case "$1" in
        done)
            printf '通过'
            ;;
        error|aborted)
            printf '异常'
            ;;
        running)
            printf '测试中'
            ;;
        *)
            printf '待测试'
            ;;
    esac
}

write_plan_table() {
    local status
    status=$(plan_status_from_watcher "$1")
    if [ "${CURRENT_PLAN_STATUS}" = "${status}" ] && [ -f "${PLAN_FILE}" ]; then
        return 0
    fi
    CURRENT_PLAN_STATUS="${status}"
    mkdir -p "$(dirname "${PLAN_FILE}")" 2>/dev/null || true
    {
        echo "# 任务计划表"
        echo
        echo "| 模型 | 测试工具 | 加速卡型号 | 状态 | 时间戳 |"
        echo "|---|---|---|---|---|"
        echo "| $(markdown_cell "${REPORT_MODEL}") | $(markdown_cell "${TEST_TOOL}") | $(markdown_cell "${ACCELERATOR}") | ${status} | $(date '+%Y-%m-%d %H:%M:%S') |"
        echo
        echo "状态只使用：待测试、测试中、通过、异常。"
    } > "${PLAN_FILE}"
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
  "container": "${CONTAINER_NAME}"
}
EOF
    write_report "$1" "$2" "$3"
    write_plan_table "$1"
}

in_container() {
    [ -n "${CONTAINER_NAME}" ]
}

log_exists() {
    if [ "${LOG_FILE}" = "none" ] || [ "${LOG_FILE}" = "-" ]; then
        return 1
    fi
    if in_container; then
        docker exec "${CONTAINER_NAME}" test -f "${LOG_FILE}" >/dev/null 2>&1
    else
        test -f "${LOG_FILE}"
    fi
}

completion_done() {
    if [ -n "${COMPLETION_CHECK_CMD}" ]; then
        if bash -lc "${COMPLETION_CHECK_CMD}" >/tmp/watch_accuracy_completion.out 2>&1; then
            cat /tmp/watch_accuracy_completion.out
            return 0
        fi
    fi
    if [ -n "${DONE_FILE}" ] && [ -s "${DONE_FILE}" ]; then
        printf '%s\n' "${DONE_FILE}"
        return 0
    fi
    if [ -n "${SUMMARY_GLOB}" ]; then
        SUMMARY_FILE=$(ls -1 ${SUMMARY_GLOB} 2>/dev/null | tail -1)
        if [ -n "${SUMMARY_FILE}" ]; then
            printf '%s\n' "${SUMMARY_FILE}"
            return 0
        fi
    fi
    return 1
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

write_status "running" "监控启动，等待评测日志..." ""

while true; do
    if DONE_DETAIL=$(completion_done); then
        write_status "done" "测试已完成" "${DONE_DETAIL}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 监控：测试完成，退出监控。"
        exit 0
    fi

    if ! log_exists; then
        write_status "running" "等待评测输出或 summary 生成..." ""
        sleep "${CHECK_INTERVAL}"
        continue
    fi

    LAST_LINES=$(tail_log)
    TOTAL_LINES=$(count_log_lines)

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
