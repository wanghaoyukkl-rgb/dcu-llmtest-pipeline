# 当前版本说明

当前版本：`v0.6.5-alpha`

仅当用户询问 skill 当前能力、边界、版本变化，或维护 skill 时读取本文件。普通推理/测试任务不需要加载。

## 当前版本特性

- 当前版本作为 `v0.6.5-alpha` 发布版，统一 evalscope/OpenCompass watcher 执行逻辑，并新增四态 Markdown 任务计划表。
- v0.6.4-alpha 新增 HYGON-AI cookbook 3 天 TTL 缓存更新机制和状态记录脚本。
- 清理旧 Qwen 示例启动脚本和旧版 HTML 思维导图，减少仓库噪声。
- `SKILL.md` 已瘦身为入口和引用导航，详细服务启动与精度测试流程拆分到 `references/service_workflow.md` 和 `references/accuracy_workflow.md`。
- 删除拼写错误且已过时的旧评测框架文件，统一使用 `references/evaluation_framework/install_evaluation_framework.md`。
- 支持三种工作模式入口：通用完整流程、高自定义流程、多模型自动计划。
- 支持多模型自动计划模式：查找节点资源、收集模型/卡型/测试类型、查询 cookbook 资源需求、生成并行/串行计划表，用户确认后按波次执行。
- 多模型、多波次或跨小时/跨天任务进入后台 orchestrator 模式：生成 `plan.json/state.json/events.log`，由独立后台进程推进排队任务，不依赖 Agent 会话持续在线。
- 支持读取 `references/node/nodes.md` 中的节点清单，并通过 `hy-smi` 查询 DCU 节点占用、频率、驱动版本和加速卡型号。
- 支持按 `references/container/create_docker_container.md` 创建 DCU 推理测试容器，包含 DCU 设备、hyhal、模型目录、数据集目录和工作目录挂载规范。
- 支持统一模型挂载和启动路径：由用户提供宿主机模型目录，创建容器时只读挂载到 `/model/<模型名>`，vLLM/SGLang 启动参数统一使用该容器内路径。
- 容器创建固定使用 `docker run -itd`，容器名格式为 `<加速卡型号>-<YYYYMMDD>-<模型名>-<框架名>`。
- 支持服务启动脚本准备：已有脚本直接使用，缺失时可由用户提供或参考 cookbook 生成。
- 支持基于 HYGON-AI `dcu-inference-cookbook/docs/model-deployment/` 的 vLLM/SGLang 最佳实践生成模型服务启动脚本；详见 `references/model_deployment_cookbook.md`。
- 支持 cookbook 本地稀疏缓存自动维护：读取 cookbook 前运行 `scripts/update_cookbook_cache.py --check`，超过 3 天才重新拉取；用户要求更新时运行 `--force`；状态写入 `~/.cache/dcu-llmtest-pipeline/cookbook_state.json`。
- 支持本地 `VLLM测试指导.md` 作为 vLLM 补充方案来源；当 GitHub cookbook 未覆盖目标模型时，读取 `references/vllm_test_guidance.md` 和 `references/VLLM测试指导.md` 查找测试方案。
- 支持本地 `SGLANG测试指导.md` 作为 SGLang 补充方案来源；当 GitHub cookbook 未覆盖目标模型时，读取 `references/sglang_test_guidance.md` 和 `references/SGLANG测试指导.md` 查找测试方案。
- `references/VLLM测试指导.md` 已隐去姓名和团队署名，仅保留模型名称、量化属性、卡型和测试方案。
- `references/SGLANG测试指导.md` 已隐去人员标记、内网 IP、内部链接、内部主目录/日志路径和 shell prompt，仅保留模型名称、卡型和测试方案。
- 支持 vLLM/SGLang 服务就绪监控：`watch_llm_ready.sh` 默认探活 `/health`、`/v1/models`、`/server_info`、`/get_server_info`。
- 服务监控采用低 token 状态文件机制：Agent 正常只读取 `/tmp/llm_status.json`，失败或超时时才读取少量日志上下文。
- 支持 `evalscope` 与 `opencompass` 两种精度评测工具选择；evalscope 可使用 `eval_accuracy.sh`，两者安装方式见 `references/evaluation_framework/install_evaluation_framework.md`。
- 所有 `pip install` 默认使用清华源 `-i https://pypi.tuna.tsinghua.edu.cn/simple`，避免默认源下载卡住。
- 精度测试启动前必须检查容器内评测工具环境；OpenCompass 正式评测和续跑前直接安装 `math_verify`、`latex2sympy2_extended`、`antlr4-python3-runtime`、`human-eval`，不要先逐个 import 检查这些常用依赖。
- 新增 OpenCompass API 配置模板 `references/opencompass_config_template.md`；默认只替换 `openai_api_base`、`tokenizer_path`、`path`、`abbr`、`work_dir`，数据集默认固定为 `gsm8k`、`math-500`、`openai_humaneval`。
- 支持 OpenCompass 续跑/补评估规则：已有 prediction/result 时使用 `-m eval -r <timestamp> -w <work_dir>` 复评，推理中断或补缺 prediction 时使用 `-m infer -r <timestamp> -w <work_dir>`。
- 默认数据集宿主机路径为 `/public/home/wanghy18/opencompass/data`，容器内挂载为 `/mnt/opencompass/data`；缺失时向用户索要路径。
- evalscope 支持 gsm8k、humaneval、math_500 本地数据集特殊参数，避免 `BuilderConfig 'main' not found` 和 math_500 `answer` 字段错误。
- 多模型多数据集测试按模型独立推进数据集队列：某个模型完成当前数据集后可立即进入下一个数据集，不等待其他模型完成。
- 精度评测启动前改为服务 `ready` 后 curl 样本检查：调用 `/v1/chat/completions` 询问“介绍一下人工智能发展史”，响应正常且无乱码才继续评测，失败或疑似乱码则中断当前任务、释放加速卡资源并保留容器。
- 精度测试启动成功后，evalscope 和 OpenCompass 都走统一 watcher 逻辑；短任务默认 10 分钟 watch 一次，长时间任务默认 30 分钟一次或由用户手动查询。
- 多模型或长时间任务必须由后台 orchestrator 维护 `state.json`、`events.log`、`orchestrator.log`、`reports/task_plan.md` 和 `reports/test_report.md`，不要依赖 Agent 会话内临时监控脚本。
- 长队列后台 orchestrator 在任务完成、失败、watcher `error/aborted`、curl 样本响应异常/乱码或超时时，记录错误、执行 release 命令释放资源、将任务标为终态，并继续调度后续 pending 模型；默认释放命令为 `docker stop <container>`，容器 stopped 保留。
- 每次执行任务都会生成并持续更新 `reports/task_plan.md` 和 `reports/test_report.md`；任务计划表固定为 `模型/测试工具/加速卡型号/状态/时间戳`，状态只使用 `待测试/测试中/通过/异常`。

## 当前版本边界

- 性能测试流程仍处于占位阶段，尚未提供标准压测脚本和吞吐/延迟指标汇总。
- 高自定义模式已有入口描述，但执行步骤还未像完整流程一样细化。
- 模型服务启动脚本不再依赖本地 Qwen 示例脚本；优先参考 HYGON-AI cookbook，cookbook 未覆盖时再按框架查本地 vLLM/SGLang 测试指导或请求用户提供脚本。
- 自动计划模式暂只支持单机模型：一个模型任务只绑定一个节点，不考虑跨节点模型。
- evalscope/opencompass 已有安装、选择、常见本地数据集规则、OpenCompass 配置模板和续跑规则；复杂数据集转换和离线依赖处理仍需继续补齐。
- 精度报告模板已移入 `references/accuracy_report_template.md`，仅在用户要求报告格式或需要生成正式报告时读取。
- 自动报告到聊天依赖当前 Agent 会话仍可执行工具；后台 watcher/orchestrator 只能写状态、事件和报告文件，无法在会话结束或运行环境回收后主动唤醒 Agent。长队列的后续任务推进必须由 orchestrator 完成，而不是依赖 Agent 前台轮询。
