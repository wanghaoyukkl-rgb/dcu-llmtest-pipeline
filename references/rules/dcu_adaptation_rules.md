# DCU Megatron 架构适配与规则知识库 
**【第一指令】本文件供 AI Agent 自动读取使用。在生成 Megatron 训练脚本时，必须严格以给定的基础 `train.sh` 模板为底座。除了根据 `config.json` 计算得出的模型架构参数、并行切分策略外，模板中的其他任何 Bash 逻辑、循环处理、非模型相关的环境变量定义，一概不准修改、删除或重构！**

## 0. 模板修改边界界定 (严格遵守)
- **允许修改的区域**：
  - `GPT_MODEL_ARGS`：网络架构核心参数。
  - `TRAINING_ARGS`：训练开关（如偏置、学习率、激活函数）。
  - `MODEL_PARALLEL_ARGS`：TP/PP/CP/EP 切分策略。
- **严禁修改的区域**：
  - 文件开头的参数解析循环 (`for para in $*...`)。
  - Profiling 相关的环境变量设定 (`MIOPEN_DEBUG_*`, `ROCBLAS_*` 等)。
  - DCU 底层环境变量 (`GLOG_minloglevel`, `HSA_FORCE_FINE_GRAIN_PCIE`, `NVTE_*` 等)。
  - 启动命令拼接逻辑 (`APP="python -u ..."` 及后续的 if 判断)。

## 1. 核心网络参数推导规则

### 1.1 FFN 隐藏层维度 (FFN Hidden Size)
- **通用规则**：如果 config 中存在 `intermediate_size` 或 `moe_intermediate_size`，优先直接使用。
- **Llama 架构推导公式**：如果缺失，根据 SwiGLU 规范，计算公式为：
  `ffn_size = int(8/3 * hidden_size)`
  然后将 `ffn_size` 向上取整到 `multiple_of` (默认 256) 的整数倍。
  *(例如：hidden_size=4096 -> 10922.66 -> 向上取整到 256 的倍数 -> 11008)*

### 1.2 线性层偏置 (Linear Bias & QKV)
- **Llama 族 (Llama, Baichuan 等)**：原生不带偏置。
  - 必须保留：`--disable-bias-linear`
  - **严禁**添加：`--add-qkv-bias`
- **Qwen 族 (Qwen1.5, Qwen2.5)**：原生带有 QKV 偏置。
  - 必须保留：`--disable-bias-linear`
  - 必须添加：`--add-qkv-bias`

### 1.3 注意力机制 (Attention)
- **GQA (分组查询注意力)**：若 config 中 `num_key_value_heads` 存在且 `< num_attention_heads`。
  - 必须添加：`--group-query-attention`
  - 必须添加：`--num-query-groups <对应值>`
- **Flash Attention**：现代大模型默认开启。
  - 必须保留：`--use-flash-attn`

## 2. 并行切分安全规则 (Parallelism)

- **TP (Tensor Parallel)**：`num_attention_heads` 必须能被 `TP` 整除。
  - 7B~14B 模型：建议 TP=1 或 2。
- **PP (Pipeline Parallel)**：`num_hidden_layers` 必须能被 `PP` 整除。
- **EP (Expert Parallel, 仅限 MoE)**：专家总数 `num_experts` 必须能被 `EP` 整除，通常结合 `TP` 使用。