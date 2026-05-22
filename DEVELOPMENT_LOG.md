# dcu-llmtest-pipeline 开发日志

## v0.5.2-alpha - 2026-05-22

### 主要变化

- 将 `references/VLLM测试指导.docx` 转换为 `references/VLLM测试指导.md`，后续补充测试方案直接读取 Markdown。
- 移除二进制 DOCX 副本，降低仓库体积并提升 GitHub diff 可读性。
- 删除 `scripts/serve_Qwen3-8B.sh` 和 `scripts/serve_Qwen3-30B-A3B.sh`，避免 cookbook-first 规则下继续依赖旧示例脚本。
- 更新 `SKILL.md`、`references/vllm_test_guidance.md`、`references/model_deployment_cookbook.md`、`references/auto_test_plan.md` 中的引用路径。
- 保留 `watch_vllm_ready.sh` 作为兼容入口，暂不删除。

## v0.5.1-alpha - 2026-05-22

### 主要变化

- 新增 `references/VLLM测试指导.docx`，作为 HYGON-AI cookbook 未覆盖模型的 vLLM 补充测试方案来源。该文件在 v0.5.2-alpha 中已转换为 Markdown 并移除二进制副本。
- 新增 `references/vllm_test_guidance.md`，记录 DOCX 使用规则、模型索引、卡型别名映射和 blocked 状态处理。
- `SKILL.md` 版本号升级为 `v0.5.1-alpha`。
- 明确测试方案查找顺序：HYGON-AI cookbook 优先；cookbook 未覆盖且框架为 vLLM 时，再查 `VLLM测试指导.docx`；仍找不到则要求用户提供脚本。
- 明确 DOCX 卡型映射：`NMZ` -> `BW1100/BW1101`，`BMZ` -> `BW1000`，`KME` -> `K100AI`。
- 更新自动计划规则：模型资源需求查询可使用 DOCX 补充来源，计划表来源字段需标明 cookbook 或 DOCX。
- 对 DOCX 中 `暂无`、`不支持`、`有bug`、`待重新测试`、`预估需要双机` 等状态，要求标记 blocked 并询问用户处理方式。

## v0.5.0-alpha - 2026-05-22

### 版本定位

当前版本新增多模型自动计划模式，用于在多个模型、多个节点资源之间生成并行/串行执行计划。该模式先生成计划表并等待用户确认，确认后才开始创建容器、启动服务和执行测试。

### 主要变化

- 新增 `references/auto_test_plan.md`，记录多模型自动计划编排规则。
- `SKILL.md` 版本号升级为 `v0.5.0-alpha`。
- frontmatter description 增加“批量测试、多个模型、计划表”触发说明。
- 模式选择新增“多模型自动计划”。
- 在第一步中新增 `1.2 多模型自动计划编排`。
- 明确自动计划流程：查找节点资源、收集模型/卡型/测试类型、查询 cookbook 资源需求、生成计划表、用户确认后执行。
- 明确端口唯一规则：计划中每个任务端口不能重复，执行时若端口占用可重新分配并同步更新计划和启动脚本。
- 明确当前只考虑单机模型：一个任务只绑定一个节点，不考虑一个模型跨多个节点。
- 明确一个节点默认 8 张卡，同节点可并行多个任务，但并行任务卡数之和不能超过节点可用卡数。
- 明确计划表字段和 blocked 状态：`need_script`、`card_mismatch`、`no_resource` 等。

### 仍需完善

- 当前计划编排是规则化流程，尚未提供独立排程脚本。
- 性能测试参数和耗时估计还未纳入自动排程权重。
- 多节点单模型、跨节点 TP/PP/EP 暂不支持。

## v0.4.1-alpha - 2026-05-22

### 主要变化

- 将启动脚本生成规则升级为硬件/部署模式强匹配。
- 明确 cookbook 启动命令前必须写明元信息：模型、框架、cookbook 文件、加速卡型号、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- 明确默认使用 IFB 模式测试。
- 明确只有用户要求时才选择 PD 分离模式。
- 明确 cookbook 条目必须与当前节点加速卡型号对齐，例如 BW1000、BW1100、K100_AI。
- 若当前节点卡型与 cookbook 条目不一致，停止自动生成启动命令，询问用户是否能够提供适配当前卡型的脚本。
- 更新 `references/model_deployment_cookbook.md`，加入卡型、部署方式和脚本元信息规则。

## v0.4.0-alpha - 2026-05-22

### 版本定位

当前版本将模型服务启动脚本生成策略升级为 cookbook-first：后续启动 vLLM 或 SGLang 服务时，优先参考 HYGON-AI `dcu-inference-cookbook/docs/model-deployment/` 中对应框架和模型族的最佳实践。

### 主要变化

- 新增 `references/model_deployment_cookbook.md`，记录 HYGON-AI cookbook 的来源、目录、当前已确认文件和使用规则。
- `SKILL.md` 版本号升级为 `v0.4.0-alpha`。
- 在 `3.1 推理服务脚本准备` 中新增 cookbook-first 规则。
- 明确启动脚本生成前必须确认框架：`vllm` 或 `sglang`。
- 明确按模型族匹配 cookbook 文档，例如 `qwen3.md`、`qwen3.5.md`、`deepseek-v3.2.md`、`glm-5.md`、`kimi-k2.5.md`。
- 明确自动生成脚本时优先复用 cookbook 中的环境变量、启动命令、TP/PP/DP、dtype、量化方式、上下文长度、显存比例和特殊优化开关。
- 现有 `scripts/serve_*.sh` 从主模板降级为 fallback 和兼容示例；只有 cookbook 未覆盖目标模型/框架组合时才优先使用本地模板。
- 推理服务启动日志路径改为框架感知：vLLM 建议 `/tmp/vllm_serve.log`，SGLang 建议 `/tmp/sglang_serve.log`。

### 仍需完善

- 尚未把 cookbook 每个模型的最佳实践内置到本 skill，本版本只记录索引和读取规则。
- 后续可增加脚本自动生成器：输入框架、模型、硬件、卡数，自动解析 cookbook markdown 并生成 `serve_<framework>_<model>.sh`。
- 后续可增加 cookbook 缓存目录，避免每次联网读取 GitHub。

## v0.3.0-alpha - 2026-05-22

### 版本定位

当前版本定位为 DCU LLM 推理测试半自动化 alpha 版本。它已经可以串联节点查询、容器创建、推理服务启动、服务就绪监控、精度测试后台执行和精度报告汇总，但性能测试闭环和高自定义流程仍需继续完善。

### 已具备能力

- 工作模式入口：通用完整流程、高自定义流程。
- 节点资源查询：从 `references/node/nodes.md` 读取节点列表，并使用 `hy-smi` 查询占用、频率、驱动版本和加速卡型号。
- DCU 容器创建：按 `references/container/create_docker_container.md` 使用 DCU 设备、hyhal、模型目录和工作目录挂载创建推理测试容器。
- 服务脚本准备：支持复用已有 `serve_<模型名>.sh` 脚本；缺失时可由用户提供或参考现有脚本生成。
- 内置启动脚本：`serve_Qwen3-8B.sh`、`serve_Qwen3-30B-A3B.sh`。
- 通用服务监控：新增 `scripts/watch_llm_ready.sh`，支持 vLLM、SGLang 和 OpenAI-compatible 服务。
- 兼容旧入口：保留并增强 `scripts/watch_vllm_ready.sh`，旧流程可继续调用。
- 低 token 监控：服务状态写入 `/tmp/llm_status.json`，Agent 正常只读取 JSON，不反复读取完整日志。
- 多端点探活：默认尝试 `/health`、`/v1/models`、`/server_info`、`/get_server_info`。
- 增量日志扫描：watcher 只扫描新增日志，发现 `Traceback`、`OOM`、`HIP error`、`CUDA error`、`Killed` 等错误后写入 `error` 状态。
- 精度测试：`scripts/eval_accuracy.sh` 使用 evalscope 通过 OpenAI-compatible API 执行数据集评测。
- 精度长任务监控：`scripts/watch_accuracy.sh` 写入 `/tmp/eval_status.json`，支持会话断开后恢复查询进度。
- 报告模板：`SKILL.md` 中提供精度测试报告格式。

### 主要边界

- 性能测试尚未闭环：缺少标准压测脚本、参数规范、吞吐/延迟指标解析和报告模板。
- 高自定义模式未完全展开：目前主要是模式入口和目标描述，缺少细化执行步骤。
- 模型覆盖有限：现成启动脚本主要覆盖 Qwen3-8B 和 Qwen3-30B-A3B。
- 评测环境准备较薄：evalscope/opencompass 安装、数据集准备和离线环境处理仍需补齐。
- 结果解析仍可加强：精度结果目前主要依赖日志提取，后续应优先使用结构化输出文件。

### 关键文件

- `SKILL.md`：主流程、版本特性、服务监控和测试报告说明。
- `scripts/watch_llm_ready.sh`：通用 LLM 服务就绪 watcher。
- `scripts/watch_vllm_ready.sh`：vLLM 旧入口兼容 watcher。
- `scripts/eval_accuracy.sh`：evalscope 精度测试脚本。
- `scripts/watch_accuracy.sh`：精度测试后台状态 watcher。
- `references/node/nodes.md`：节点列表和查询命令。
- `references/container/create_docker_container.md`：DCU 容器创建规范。

## v0.2.0-alpha - 2026-05-21

### 主要变化

- 引入 vLLM 服务就绪 watcher 思路，避免 Agent 反复读取完整日志。
- 新增 `scripts/watch_vllm_ready.sh`，通过 HTTP health check 和增量日志扫描写入状态文件。
- 将 `SKILL.md` 中旧的 `tail -n 50` 轮询方案替换为状态文件方案。

## v0.1.0-alpha - 初始版本

### 主要能力

- 建立 DCU 推理测试完整流程草案。
- 提供节点查询、容器创建、推理服务启动、精度测试、报告生成的基础步骤。
- 提供 Qwen3 vLLM 启动脚本、evalscope 精度测试脚本和精度后台监控脚本。
