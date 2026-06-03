# dcu-llmtest-pipeline 开发日志

## v0.6.5-alpha - 2026-06-02

### 主要变化

- 当前版本声明升级为 `v0.6.5-alpha`。
- 多模型/长队列执行逻辑收敛为任务计划表驱动：执行前生成 `reports/task_plan.md`，表头固定为 `模型、测试工具、加速卡型号、状态、时间戳`。
- `reports/task_plan.md` 状态统一为四种：`待测试`、`测试中`、`通过`、`异常`；后续仅在任务启动、异常、完成等状态变化节点更新时间戳。
- `evalscope` 快速验证和 `opencompass` 正式验证统一使用 watcher 逻辑，完成判断统一支持 `status_file`、`summary_glob`、`done_file` 和 `completion_check_cmd`。
- `scripts/watch_accuracy.sh` 支持无外层日志任务传入 `none`，并可通过 `SUMMARY_GLOB`、`DONE_FILE`、`COMPLETION_CHECK_CMD` 判断完成。
- `scripts/auto_test_orchestrator.py` 新增 `watch_interval_sec` / `watch_mode` 规则：短任务默认 10 分钟，长时间任务默认 30 分钟，也支持用户手动查询 `reports/task_plan.md`。
- `references/accuracy_workflow.md`、`references/auto_test_plan.md`、`references/evaluation_framework/install_evaluation_framework.md` 和 `references/current_version.md` 同步更新统一 watcher、四态任务计划表和双报告文件规则。
- 按 skill-creator 校验要求移除 `SKILL.md` frontmatter 中的非标准 `version` 字段，版本号保留在正文与 `references/current_version.md`。

## v0.6.4-alpha - 2026-05-29

### 主要变化

- `SKILL.md` 版本号升级为 `v0.6.4-alpha`。
- 新增 `scripts/update_cookbook_cache.py`，用于维护 HYGON-AI cookbook 本地稀疏缓存，默认缓存到 `~/.cache/dcu-llmtest-pipeline/dcu-inference-cookbook`。
- cookbook 更新状态写入 `~/.cache/dcu-llmtest-pipeline/cookbook_state.json`，记录 `last_update_utc`、`head_commit`、`head_commit_date` 和 `last_checked_utc`。
- `references/model_deployment_cookbook.md` 增加 3 天 TTL 策略：读取 cookbook 前执行 `--check`，超过 3 天自动拉取；用户明确要求更新时执行 `--force`。
- `references/accuracy_workflow.md` 和 `references/auto_test_plan.md` 增加精度测试/续跑/计划生成前的 cookbook 缓存检查要求。
- 修改前已备份当前 skill 到 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline_20260529-165721`。

## v0.6.3-alpha - 2026-05-29

### 主要变化

- `SKILL.md` 版本号升级为 `v0.6.3-alpha`。
- 新增脱敏版 `references/SGLANG测试指导.md`，移除人员标记、内网 IP、内部链接、内部主目录/日志路径和 shell prompt，仅保留模型、卡型和 SGLang 启动建议。
- 新增 `references/sglang_test_guidance.md`，记录 SGLang 本地补充来源的使用优先级、模型索引、卡型别名、blocked 状态和占位符处理规则。
- 更新 `SKILL.md`、`references/service_workflow.md`、`references/model_deployment_cookbook.md` 和 `references/auto_test_plan.md`，使 cookbook 未覆盖且框架为 SGLang 时可回退到本地补充指导。
- 修改前已备份当前 skill 和原始 SGLang 指导到 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline_20260529-163921`。

## v0.6.2-alpha - 2026-05-27

### 主要变化

- `SKILL.md` 版本号升级为 `v0.6.2-alpha`。
- OpenCompass 正式评测和续跑前，常用评测依赖改为直接执行固定安装命令：`pip install math_verify latex2sympy2_extended antlr4-python3-runtime human-eval -i https://pypi.tuna.tsinghua.edu.cn/simple`，不再先逐个 import 检查。
- `scripts/auto_test_orchestrator.py` 将 `datetime.fromisoformat` 替换为兼容 Python 3.6 的时间解析，避免后台监控在老系统 Python 中崩溃，导致需要人工补齐 `state.json/events.log`。

## v0.6.1-alpha - 2026-05-26

### 主要变化

- `SKILL.md` 版本号升级为 `v0.6.1-alpha`。
- 所有 `pip install` 规则默认加清华源 `-i https://pypi.tuna.tsinghua.edu.cn/simple`，避免评测依赖安装时因默认源卡住。
- OpenCompass 正式评测依赖检查补充 `antlr4`，安装说明补充 `antlr4-python3-runtime`，修复 `math-500` eval 阶段可能无得分输出的问题。
- 新增 `references/opencompass_config_template.md`，默认固定 `gsm8k`、`math-500`、`openai_humaneval`，常规任务只替换 `openai_api_base`、`tokenizer_path`、`path`、`abbr`、`work_dir`。
- 调整 OpenCompass 监控规则：长任务和多模型任务必须使用 orchestrator 写 `state.json/events.log/orchestrator.log`，不再依赖 Agent 会话内临时 `monitor_status.py`。
- OpenCompass 任务不再额外生成 `<model>.eval.log` 外层评测日志，进度和错误优先读取 OpenCompass 输出目录下的 `logs/infer/`、`logs/eval/`、`summary/`。
- `scripts/auto_test_orchestrator.py` 支持通过 `summary_glob`、`done_file` 或 `completion_check_cmd` 判断任务完成，并将事件同时写入 `events.log` 和 stdout，避免 `orchestrator.log` 为空。
- 任务终态后默认执行 `docker stop <container>` 释放 DCU 资源，容器以 stopped 状态保留；失败任务释放当前资源后继续后续队列。
- README 目录结构改为带注释的文件清单，说明每个入口文件、引用文档和脚本的用途。
- 已对 `auto_test_orchestrator.py` 做语法编译检查，并用 `/tmp` 下的最小计划验证事件、状态和 summary 输出。

## v0.6.0-alpha - 2026-05-25

### 主要变化

- `SKILL.md` 版本号升级为 `v0.6.0-alpha`。
- `references/current_version.md` 同步更新当前版本号。
- 新增 `README.md`，面向 GitHub 仓库说明 skill 能力、目录结构、安装方式、典型流程、长队列执行和 OpenCompass 续跑入口。
- 清理旧 Qwen 示例启动脚本 `scripts/serve_Qwen3-8B.sh`、`scripts/serve_Qwen3-30B-A3B.sh`。
- 清理旧版 HTML 思维导图 `references/skill_mindmap_v0.5.9.html`，后续以 README 和拆分后的 workflow 引用作为主要导航。
- 作为 `v0.6.0-alpha` 发布版推送到 GitHub `main` 分支。

## v0.5.11-alpha - 2026-05-25

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.11-alpha`。
- 按 progressive disclosure 原则瘦身主 skill：主文件只保留模式选择、引用导航、通用执行骨架和核心约束。
- 新增 `references/service_workflow.md`，承接原主文件中的服务脚本准备、cookbook-first 规则、启动命令和 `watch_llm_ready.sh` 监控细节。
- 新增 `references/accuracy_workflow.md`，承接原主文件中的精度测试参数、evalscope/OpenCompass 执行、续跑、watcher、orchestrator、结果提取和报告生成细节。
- 删除已过时且拼写错误的 `references/evaluation_framework/intall_evaluation_framework.md`，避免和正式文件 `install_evaluation_framework.md` 重复。
- 修改前已备份当前 skill 到 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline.backup.20260525-v0.5.11-slim` 和 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline-worktree.backup.20260525-v0.5.11-slim`。

## v0.5.10-alpha - 2026-05-25

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.10-alpha`。
- OpenCompass 精度测试环境检查从 `pip list` 扩展为 import 级检查，覆盖 `opencompass`、`openai`、`math_verify`、`latex2sympy2_extended`、`human_eval`。
- 明确 OpenCompass 正式评测前需要补装常用依赖：`pip install math_verify latex2sympy2_extended human-eval`，其中 `human_eval` 的 pip 包名为 `human-eval`。
- 补充 OpenCompass 续跑/补评估流程：已有 prediction/result 但 eval 失败时使用 `-m eval -r <timestamp> -w <work_dir>`，推理中断或需要补齐 prediction 时使用 `-m infer -r <timestamp> -w <work_dir>`。
- `references/evaluation_framework/install_evaluation_framework.md` 增加 OpenCompass 依赖验证、补装命令和续跑说明。
- `references/auto_test_plan.md` 增加长队列中 OpenCompass 依赖失败后的可恢复命令记录要求。
- 修改前已备份当前 skill 到 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline.backup.20260525-v0.5.10-opencompass-resume` 和 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline-worktree.backup.20260525-v0.5.10-opencompass-resume`。

## v0.5.9-alpha - 2026-05-25

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.9-alpha`。
- 将多模型、多波次、跨小时/跨天任务的执行策略从 Agent 前台轮询升级为后台 orchestrator：生成 `plan.json/state.json/events.log/reports/`，由独立进程推进排队任务。
- 新增 `scripts/auto_test_orchestrator.py`：支持读取确认后的计划、按节点/卡资源启动 pending 任务、读取 watcher 状态、记录事件、失败释放资源并继续调度后续任务。
- 明确任务失败处理策略：服务启动失败、评测错误、watcher `error/aborted`、超时或 prediction 乱码时，记录到 `state.json/events.log`，执行 `release_cmd` 释放评测/服务进程，容器默认保留，后续队列继续执行。
- 调整 prediction 早期检查规则：每个模型只检查一次；默认评测启动 600 秒后读取前 3 条有文本 prediction，若 3 条均疑似乱码则按 `aborted: garbled_prediction` 处理。
- `watch_accuracy.sh` 增加 `prediction_check_delay` 参数，并在普通错误时也尝试释放当前评测/服务进程。
- `references/auto_test_plan.md` 增加后台 orchestrator 计划字段、落盘结构、状态流转和执行规范。
- `references/current_version.md` 同步更新 v0.5.9-alpha 能力与边界。
- 将 `scripts/auto_test_orchestrator.py` 顶部说明和主要用户可见输出调整为中文。
- 新增 `references/skill_mindmap_v0.5.9.html`，用于 HTML 形式查看当前版本能力思维导图。

## v0.5.8-alpha - 2026-05-25

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.8-alpha`。
- 精度测试启动成功后，要求 Agent 维护本轮计划状态清单，记录模型、数据集队列、节点、容器、服务端口、状态文件、日志路径和输出目录。
- 将精度测试收尾逻辑从“用户回来后按需查询”升级为“待机监控与自动报告”：当前会话仍可执行工具时，默认每 10 分钟读取 watcher 状态文件。
- 明确待机期间只读取小型 JSON 状态文件；仅在状态变化、出现 `error/aborted`、或所有计划项完成时向用户发送更新。
- 新增所有计划项完成后的自动汇总要求：收集 summary/log/result 文件，按 `<模型, 数据集>` 提取指标、样本数、耗时和输出目录，并主动推送测试报告。
- 明确自动报告边界：后台 watcher 只能写状态文件，不能在 Agent 会话结束或运行环境回收后主动唤醒 Agent。
- `references/current_version.md` 同步补充待机监控、自动报告能力和边界说明。

## v0.5.7-alpha - 2026-05-23

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.7-alpha`。
- 将当前版本特性和当前版本边界移入 `references/current_version.md`，主 skill 仅保留按需读取入口。
- 将精度报告字段和输出模板移入 `references/accuracy_report_template.md`。
- 主流程移除第三方 API 泛化表述，当前仅声明支持 vLLM 和 SGLang 服务。
- 精简 `SKILL.md`，降低默认加载负担。

## v0.5.6-alpha - 2026-05-23

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.6-alpha`。
- 精度测试流程增加容器内评测环境检查：使用 `pip list | grep` 验证 `evalscope`、`opencompass`、`openai` 等依赖，缺失时先安装再测试。
- 默认数据集宿主机路径设为 `/public/home/wanghy18/opencompass/data`，容器内挂载到 `/mnt/opencompass/data:ro`，默认路径不存在时向用户索要路径。
- `eval_accuracy.sh` 增加 gsm8k、humaneval、math_500 的本地数据集特殊参数，修复 `BuilderConfig ... Available: ['default']` 和 math_500 `answer` 字段问题的前置检查。
- `watch_accuracy.sh` 改为优先读取评测日志和 prediction 文件；支持容器内日志读取、prediction 自动查找、连续 3 条疑似乱码时中断当前任务并保留容器。
- 多模型多数据集计划改为按模型独立推进数据集队列，避免等待所有模型完成同一数据集后才进入下一个数据集。

## v0.5.5-alpha - 2026-05-22

### 主要变化

- `SKILL.md` 版本号升级为 `v0.5.5-alpha`。
- 明确 vLLM/SGLang 启动命令中的模型路径统一为 `/model/<模型名>`。
- 更新容器创建流程：由用户提供目标节点宿主机模型目录，创建容器时挂载为 `-v <宿主模型路径>:/model/<模型名>:ro`。
- 明确容器创建必须使用 `docker run -itd`，不得使用 `docker run -it`。
- 明确容器命名格式为 `<加速卡型号>-<YYYYMMDD>-<模型名>-<框架名>`。
- 更新自动计划表字段，补充宿主模型路径、容器模型路径和容器名。

## v0.5.4-alpha - 2026-05-22

### 主要变化

- 隐去 `references/VLLM测试指导.md` 中的姓名和团队署名。
- 移除导航、模型标题和卡型小节中的负责人姓名括号信息。
- 保留模型属性信息，如官方模型、社区量化、非社区量化和内部量化。
- `SKILL.md` 版本号升级为 `v0.5.4-alpha`，当前版本特性补充脱敏说明。

## v0.5.3-alpha - 2026-05-22

### 主要变化

- 将评测框架文档从 `references/evaluation_framework/intall_evaluation_framework.md` 重命名为 `references/evaluation_framework/install_evaluation_framework.md`。
- 补充 `evalscope` 与 `opencompass` 的安装方式、验证命令和选择规则。
- `SKILL.md` 版本号升级为 `v0.5.3-alpha`。
- 精度测试流程增加评测工具选择：默认 `evalscope`，用户可选择 `opencompass`。
- 精度测试执行步骤拆成 `evalscope` 和 `opencompass` 两条路径；opencompass 需要用户提供或确认配置。
- 将 `references/rules/dcu_adaptation_rules.md` 从 Megatron 训练规则改写为 DCU 推理服务适配规则。
- 移除当前版本特性中已过时的本地 Qwen 启动脚本描述。

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
- 通用服务监控：新增 `scripts/watch_llm_ready.sh`，支持 vLLM 和 SGLang 服务。
- 兼容旧入口：保留并增强 `scripts/watch_vllm_ready.sh`，旧流程可继续调用。
- 低 token 监控：服务状态写入 `/tmp/llm_status.json`，Agent 正常只读取 JSON，不反复读取完整日志。
- 多端点探活：默认尝试 `/health`、`/v1/models`、`/server_info`、`/get_server_info`。
- 增量日志扫描：watcher 只扫描新增日志，发现 `Traceback`、`OOM`、`HIP error`、`CUDA error`、`Killed` 等错误后写入 `error` 状态。
- 精度测试：`scripts/eval_accuracy.sh` 使用 evalscope 通过 vLLM/SGLang API 执行数据集评测。
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
