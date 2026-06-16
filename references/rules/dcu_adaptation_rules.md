# DCU 推理服务适配规则

本文件供 AI Agent 在生成、校验和修改 vLLM/SGLang 推理服务启动脚本时读取。它只面向推理服务，不再包含 Megatron 训练脚本规则。

## 0. 总原则

- 优先参考 HYGON-AI cookbook；cookbook 未覆盖且框架为 vLLM 时，再参考 `references/VLLM测试指导.md`。
- 一个启动脚本只能使用一个精确匹配来源：一个 cookbook 条目、一个本地测试指导条目，或用户提供的一份脚本。不得混合 cookbook 和测试指导，不得使用相邻模型、相似版本或历史脚本拼接生成。
- 不要凭经验删减 DCU、NUMA、通信、量化、MoE、IFB/PD 调度相关环境变量，也不要凭经验新增来源中没有的优化变量或参数。
- 自动生成或改写脚本只允许三类适配：添加/设置 `HIP_VISIBLE_DEVICES`、把模型路径替换为容器内 `/model/<模型名>`、以及为避免端口冲突或支持同节点并发而新增/修改服务监听端口。其它 dtype、TP/PP/DP、量化、`-cc`/编译配置、上下文长度、显存比例、调度参数均必须按来源原样保留。
- 默认使用 IFB 模式；只有用户明确要求时才使用 PD 分离模式。
- 当前只考虑单机模型，一个任务绑定一个节点，默认一个节点 8 张卡。
- 若来源方案需要多节点或超过 8 卡，标记 blocked，并询问用户是否提供适配脚本或调整测试目标。

## 1. 卡型与来源匹配

- cookbook 或本地补充文档中的卡型必须与当前节点卡型一致。
- `NMZ` / `nmz` 规范化为 `BW1100` 或 `BW1101`。
- `BMZ` / `bmz` 规范化为 `BW1000`。
- `KME` / `K100_AI` / `K100AI` 规范化为 `K100AI`。
- 若当前节点卡型和来源方案卡型不一致，不要强行改写命令；询问用户是否换节点或提供适配脚本。
- 若找不到精确匹配来源，直接询问用户是否提供脚本；用户无法提供时跳过或 blocked。

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

- 端口优先沿用来源文档里的固定端口；若来源未写端口则使用框架默认端口。
- vLLM 默认端口：`8000`。
- SGLang 默认端口：`30000`。
- 同一计划中端口必须全局唯一。
- 若来源端口已被占用，或多个同波次任务会使用同一默认端口，可以自主选择目标节点上的空闲端口，并同步更新启动脚本、curl 探活端口、`probe_url` 和评测 API base。
- vLLM 端口适配优先使用 `--port <port>`；SGLang 端口适配优先使用 `--port <port>` 或来源脚本已有的端口变量。只允许修改服务监听端口，不得顺手改动 `--dist-init-addr`、master/bootstrap 端口、host IP 等分布式通信字段，除非用户明确授权。
- 每次端口改动必须写入脚本注释和计划来源说明，例如 `Port adaptation: 8000 -> 8001 for same-node parallelism`。
- vLLM/SGLang 服务日志必须由启动器重定向到当前 `<run_dir>/serve_logs/<task_id>.serve.log`；不要把服务日志固定到容器 `/tmp`。

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
- 来源没有明确卡数、TP 或其它关键参数时，标记 blocked 并询问用户提供脚本；不得根据模型规模和当前卡型推断。

## 6. 服务就绪校验

- 旧服务监控脚本已移除；当前服务阶段使用 `scripts/watch_model_once.sh serve ...` 每 2 分钟观察服务日志尾 10 行并做 HTTP 探活。
- HTTP 探活 ready 后，必须执行 `/v1/chat/completions` curl 样本检查作为启动评测前门禁。
- 脚本启动报错或服务未 ready 时，立即标记异常、记录少量日志并释放资源；不得自动改参数、换来源或重启试错。
