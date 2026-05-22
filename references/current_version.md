# 当前版本说明

当前版本：`v0.5.7-alpha`

仅当用户询问 skill 当前能力、边界、版本变化，或维护 skill 时读取本文件。普通推理/测试任务不需要加载。

## 当前版本特性

- 支持两种工作模式入口：通用完整流程、高自定义流程。
- 支持多模型自动计划模式：查找节点资源、收集模型/卡型/测试类型、查询 cookbook 资源需求、生成并行/串行计划表，用户确认后按波次执行。
- 支持读取 `references/node/nodes.md` 中的节点清单，并通过 `hy-smi` 查询 DCU 节点占用、频率、驱动版本和加速卡型号。
- 支持按 `references/container/create_docker_container.md` 创建 DCU 推理测试容器，包含 DCU 设备、hyhal、模型目录、数据集目录和工作目录挂载规范。
- 支持统一模型挂载和启动路径：由用户提供宿主机模型目录，创建容器时只读挂载到 `/model/<模型名>`，vLLM/SGLang 启动参数统一使用该容器内路径。
- 容器创建固定使用 `docker run -itd`，容器名格式为 `<加速卡型号>-<YYYYMMDD>-<模型名>-<框架名>`。
- 支持服务启动脚本准备：已有脚本直接使用，缺失时可由用户提供或参考 cookbook 生成。
- 支持基于 HYGON-AI `dcu-inference-cookbook/docs/model-deployment/` 的 vLLM/SGLang 最佳实践生成模型服务启动脚本；详见 `references/model_deployment_cookbook.md`。
- 支持本地 `VLLM测试指导.md` 作为 vLLM 补充方案来源；当 GitHub cookbook 未覆盖目标模型时，读取 `references/vllm_test_guidance.md` 和 `references/VLLM测试指导.md` 查找测试方案。
- `references/VLLM测试指导.md` 已隐去姓名和团队署名，仅保留模型名称、量化属性、卡型和测试方案。
- 支持 vLLM/SGLang 服务就绪监控：`watch_llm_ready.sh` 默认探活 `/health`、`/v1/models`、`/server_info`、`/get_server_info`。
- 服务监控采用低 token 状态文件机制：Agent 正常只读取 `/tmp/llm_status.json`，失败或超时时才读取少量日志上下文。
- 支持 `evalscope` 与 `opencompass` 两种精度评测工具选择；evalscope 可使用 `eval_accuracy.sh`，两者安装方式见 `references/evaluation_framework/install_evaluation_framework.md`。
- 精度测试启动前必须检查容器内评测工具环境；缺少 `evalscope`、`opencompass` 或 `openai` 等依赖时先安装再测试。
- 默认数据集宿主机路径为 `/public/home/wanghy18/opencompass/data`，容器内挂载为 `/mnt/opencompass/data`；缺失时向用户索要路径。
- evalscope 支持 gsm8k、humaneval、math_500 本地数据集特殊参数，避免 `BuilderConfig 'main' not found` 和 math_500 `answer` 字段错误。
- 多模型多数据集测试按模型独立推进数据集队列：某个模型完成当前数据集后可立即进入下一个数据集，不等待其他模型完成。
- 精度监控使用评测日志和 prediction 早期检查；若连续 3 条 prediction 疑似乱码，中断当前任务、释放加速卡资源并保留容器。

## 当前版本边界

- 性能测试流程仍处于占位阶段，尚未提供标准压测脚本和吞吐/延迟指标汇总。
- 高自定义模式已有入口描述，但执行步骤还未像完整流程一样细化。
- 模型服务启动脚本不再依赖本地 Qwen 示例脚本；优先参考 HYGON-AI cookbook，cookbook 未覆盖时再查本地 VLLM 测试指导或请求用户提供脚本。
- 自动计划模式暂只支持单机模型：一个模型任务只绑定一个节点，不考虑跨节点模型。
- evalscope/opencompass 已有安装、选择和常见本地数据集规则；复杂数据集转换、离线依赖处理和 OpenCompass 具体配置模板仍需继续补齐。
- 精度报告模板已移入 `references/accuracy_report_template.md`，仅在用户要求报告格式或需要生成正式报告时读取。
