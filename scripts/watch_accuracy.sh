#!/bin/bash
# 精度测试后台监控脚本
# 在宿主机上通过 nohup 运行，不依赖 Claude session 保持连接
# 每隔 CHECK_INTERVAL 秒扫描一次日志，将当前状态写入 STATUS_FILE
#
# 用法（宿主机执行）：
#   nohup bash watch_accuracy.sh <log_file> <status_file> &
#
# 状态文件格式（JSON，Claude 可直接读取）：
#   {"status": "running|done|error", "progress": "...", "last_check": "...", "result": "..."}

LOG_FILE=${1:-"/tmp/eval_accuracy.log"}
STATUS_FILE=${2:-"/tmp/eval_status.json"}
CHECK_INTERVAL=600   # 10 分钟检查一次

write_status() {
    local status=$1
    local progress=$2
    local result=$3
    cat > "${STATUS_FILE}" <<EOF
{
  "status": "${status}",
  "progress": "${progress}",
  "last_check": "$(date '+%Y-%m-%d %H:%M:%S')",
  "result": "${result}",
  "log_file": "${LOG_FILE}"
}
EOF
}

write_status "running" "监控启动，等待日志..." ""

while true; do
    if [ ! -f "${LOG_FILE}" ]; then
        write_status "running" "日志文件尚未生成，等待任务启动..." ""
        sleep ${CHECK_INTERVAL}
        continue
    fi

    LAST_LINES=$(tail -n 80 "${LOG_FILE}" 2>/dev/null)
    TOTAL_LINES=$(wc -l < "${LOG_FILE}" 2>/dev/null)

    # 检查是否完成（evalscope 完成后会输出包含 accuracy 的结果行）
    if echo "${LAST_LINES}" | grep -qiE "(accuracy|score|result|测试完成|完成)"; then
        # 提取精度数值行
        RESULT_LINE=$(echo "${LAST_LINES}" | grep -iE "(accuracy|score)" | tail -5)
        write_status "done" "测试已完成（共 ${TOTAL_LINES} 行日志）" "${RESULT_LINE}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 监控：测试完成，退出监控。"
        exit 0
    fi

    # 检查是否出错
    if echo "${LAST_LINES}" | grep -qiE "(error|traceback|exception|failed|killed)"; then
        ERR_LINE=$(echo "${LAST_LINES}" | grep -iE "(error|traceback|exception|failed|killed)" | tail -3)
        write_status "error" "检测到错误（第 ${TOTAL_LINES} 行）" "${ERR_LINE}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 监控：发现错误，退出监控。"
        exit 1
    fi

    # 正在运行：记录当前进度（取最后 3 行作为进度快照）
    PROGRESS=$(echo "${LAST_LINES}" | tail -3 | tr '\n' ' ' | sed 's/"/\\"/g')
    write_status "running" "${PROGRESS}（共 ${TOTAL_LINES} 行）" ""

    sleep ${CHECK_INTERVAL}
done
