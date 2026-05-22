#!/bin/bash
# 精度测试脚本模板
# 使用方式：bash eval_accuracy.sh <模型名> [数据集] [limit]
# 示例：bash eval_accuracy.sh Qwen3-8B gsm8k 10
#
# 参数说明：
#   MODEL_NAME  - 模型目录名（位于 /model/ 下）
#   DATASET     - 数据集名称，默认 gsm8k
#   LIMIT       - 测试条数，默认 10

MODEL_NAME=${1:-"Qwen3-8B"}
DATASET=${2:-"gsm8k"}
LIMIT=${3:-"10"}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始精度测试"
echo "  模型: /model/${MODEL_NAME}"
echo "  数据集: ${DATASET}"
echo "  条数限制: ${LIMIT}"
echo "---"

evalscope eval \
  --model /model/${MODEL_NAME} \
  --api-url http://127.0.0.1:8000/v1 \
  --api-key EMPTY \
  --generation-config max_tokens=16384,temperature=0.0 \
  --eval-type openai_api \
  --eval-batch-size 32 \
  --datasets ${DATASET} \
  --limit ${LIMIT} \
  --dataset-hub Local \
  --dataset-args "{
    \"${DATASET}\": {\"dataset_id\": \"/mnt/opencompass/data/${DATASET}\"}
  }"

EXIT_CODE=$?
echo "---"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 精度测试完成，退出码: ${EXIT_CODE}"
