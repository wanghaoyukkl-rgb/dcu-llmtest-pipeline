# DCU 推理服务适配规则

本文件供 AI Agent 在生成、校验和修改 vLLM/SGLang 推理服务启动脚本时读取。它只面向推理服务，不再包含 Megatron 训练脚本规则。

## 0. 总原则

- 优先参考 HYGON-AI cookbook；cookbook 未覆盖且框架为 vLLM 时，再参考 `references/VLLM测试指导.md`。
- 不要凭经验删减 DCU、NUMA、通信、量化、MoE、IFB/PD 调度相关环境变量。
- 默认使用 IFB 模式；只有用户明确要求时才使用 PD 分离模式。
- 当前只考虑单机模型，一个任务绑定一个节点，默认一个节点 8 张卡。
- 若来源方案需要多节点或超过 8 卡，标记 blocked，并询问用户是否提供适配脚本或调整测试目标。

## 1. 卡型与来源匹配

- cookbook 或本地补充文档中的卡型必须与当前节点卡型一致。
- `NMZ` / `nmz` 规范化为 `BW1100` 或 `BW1101`。
- `BMZ` / `bmz` 规范化为 `BW1000`。
- `KME` / `K100_AI` / `K100AI` 规范化为 `K100AI`。
- 若当前节点卡型和来源方案卡型不一致，不要强行改写命令；询问用户是否换节点或提供适配脚本。

## 2. 启动脚本元信息

生成脚本时，文件开头必须写明：

- 模型名称
- 推理框架：`vllm` 或 `sglang`
- 方案来源：cookbook 文件或 `references/VLLM测试指导.md`
- 来源条目：模型标题和卡型小节
- 当前节点卡型
- 部署模式：`IFB` 或 `PD`
- 推荐卡数和实际卡 ID
- TP/PP/DP
- dtype 和量化方式
- 服务端口和日志路径

## 3. 端口与日志

- 端口由计划表统一分配，不能沿用来源文档里的固定端口。
- vLLM 默认端口池：`8000-8099`。
- SGLang 默认端口池：`30000-30099`。
- 同一计划中端口必须全局唯一。
- vLLM 日志建议：`/tmp/vllm_serve.log`。
- SGLang 日志建议：`/tmp/sglang_serve.log`。
- 执行时如端口已占用，重新分配端口并同步更新计划表、启动脚本和 watcher 参数。

## 4. 环境变量保护

以下类型变量不得随意删除：

- DCU/HIP/ROCm：`HIP_VISIBLE_DEVICES`、`HSA_FORCE_FINE_GRAIN_PCIE`、`HIP_*`、`ROCR_*`。
- 通信：`NCCL_*`、`GLOO_SOCKET_IFNAME`、`ALLREDUCE_STREAM_WITH_COMPUTE`、`SENDRECV_STREAM_WITH_COMPUTE`、`Allgather_Base_STREAM_WITH_COMPUTE`。
- NUMA：`VLLM_NUMA_BIND`、`VLLM_RANK*_NUMA`、SGLang `--numa-node`。
- vLLM 优化：`VLLM_*`、`LMSLIM_*`、`USE_FUSED_*`、`USE_LIGHTOP_*`。
- SGLang 优化：`SGLANG_*`、`USE_DCU_CUSTOM_ALLREDUCE`、`USE_SPE_MQP`。
- 量化/MoE/MLA/DSA 相关参数：`--kv-cache-dtype`、`-q`、`--quantization`、`--attention-backend`、`--speculative_config`、`--enable-chunked-prefill` 等。

若确实要删改，必须说明来源方案、删改原因和风险，并得到用户确认。

## 5. 并行切分安全检查

- TP 不得超过当前任务分配卡数。
- PP/TP 组合所需卡数不得超过当前节点空闲卡数。
- 一个 8 卡任务独占一个节点当前波次。
- 小模型可同节点并行，但并行任务卡数之和不能超过节点空闲卡数。
- 对 cookbook 或本地补充文档已明确给出的 TP/PP/DP，以来源方案为准。
- 来源没有明确卡数时，先根据模型规模和当前卡型推断，并向用户说明推断依据。

## 6. 服务就绪校验

- 启动服务后必须使用 `watch_llm_ready.sh` 写入 `/tmp/llm_status.json`。
- 只有 `status == "ready"` 时才能触发精度或性能测试。
- 失败或超时时只读取少量日志上下文，不读取完整日志。
