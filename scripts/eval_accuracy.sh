#!/bin/bash
# 精度测试脚本模板
# 使用方式：bash eval_accuracy.sh <模型名> [数据集] [limit] [api_port]
# 示例：bash eval_accuracy.sh Qwen3-8B gsm8k 10 8000
#
# 参数说明：
#   MODEL_NAME  - 模型目录名（位于 /model/ 下）
#   DATASET     - 数据集名称，默认 gsm8k
#   LIMIT       - 测试条数，默认 10
#   API_PORT    - 推理服务端口，默认 8000

MODEL_NAME=${1:-"Qwen3-8B"}
DATASET=${2:-"gsm8k"}
LIMIT=${3:-"10"}
API_PORT=${4:-"8000"}

if ! pip list 2>/dev/null | grep -qi "evalscope"; then
  echo "[ERROR] 当前容器未检测到 evalscope，请先安装 evalscope 后再运行精度测试。"
  exit 127
fi

DATASET_KEY="${DATASET}"
DATASET_ARGS=""

case "${DATASET}" in
  gsm8k)
    DATASET_ARGS='{"gsm8k": {"local_path": "/mnt/opencompass/data/gsm8k", "subset_list": ["default"]}}'
    ;;
  humaneval|openai_humaneval|human_eval)
    DATASET_KEY="humaneval"
    DATASET_ARGS='{"humaneval": {"local_path": "/mnt/opencompass/data/humaneval", "subset_list": ["default"]}}'
    ;;
  math_500|math500|math)
    DATASET_KEY="math_500"
    DATASET_ARGS='{"math_500": {"local_path": "/mnt/opencompass/data/math", "subset_list": ["default"]}}'
    if [ ! -f "/mnt/opencompass/data/math/test.jsonl" ]; then
      echo "[ERROR] math_500 默认期望文件不存在：/mnt/opencompass/data/math/test.jsonl"
      exit 2
    fi
    if ! head -n 20 /mnt/opencompass/data/math/test.jsonl | grep -q '"answer"'; then
      echo "[ERROR] math_500 数据样本缺少 answer 字段。不要直接截断破坏字段，请使用 --limit 控制样本数。"
      exit 2
    fi
    ;;
  *)
    if [ ! -d "/mnt/opencompass/data/${DATASET}" ]; then
      echo "[ERROR] 数据集目录不存在：/mnt/opencompass/data/${DATASET}"
      exit 2
    fi
    DATASET_ARGS="{\"${DATASET}\": {\"local_path\": \"/mnt/opencompass/data/${DATASET}\"}}"
    ;;
esac

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始精度测试"
echo "  模型: /model/${MODEL_NAME}"
echo "  数据集: ${DATASET_KEY}"
echo "  条数限制: ${LIMIT}"
echo "  API: http://127.0.0.1:${API_PORT}/v1"
echo "  dataset-args: ${DATASET_ARGS}"
echo "---"

LIMIT_ARGS=()
if [ -n "${LIMIT}" ] && [ "${LIMIT}" != "0" ]; then
  LIMIT_ARGS=(--limit "${LIMIT}")
fi

evalscope eval \
  --model /model/${MODEL_NAME} \
  --api-url http://127.0.0.1:${API_PORT}/v1 \
  --api-key EMPTY \
  --generation-config max_tokens=16384,temperature=0.0 \
  --eval-type openai_api \
  --eval-batch-size 32 \
  --datasets ${DATASET_KEY} \
  "${LIMIT_ARGS[@]}" \
  --dataset-hub Local \
  --dataset-args "${DATASET_ARGS}"

EXIT_CODE=$?
echo "---"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 精度测试完成，退出码: ${EXIT_CODE}"
exit ${EXIT_CODE}
