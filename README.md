# dcu-llmtest-pipeline

DCU LLM 推理与精度测试自动化 Codex Skill。

当前版本：`v0.6.5-alpha`

## 能力概览

- 查询 DCU 节点资源、卡型、占用、端口和驱动信息。
- 创建或复用 DCU 推理测试容器，统一模型挂载路径为 `/model/<模型名>`。
- 基于 HYGON-AI `dcu-inference-cookbook` 优先生成或校验 vLLM/SGLang 启动脚本。
- 自动维护 cookbook 本地稀疏缓存，默认 3 天检查更新一次，用户要求时可强制更新。
- cookbook 未覆盖时，可按框架读取本地脱敏版 vLLM/SGLang 测试指导作为补充来源。
- 使用 watcher 低频状态文件监控推理服务就绪，避免反复读取大日志。
- 支持 `evalscope` 与 `opencompass` 精度测试。
- 支持 OpenCompass 常用评测依赖固定安装、`-m eval -r <timestamp>` 补评估和 `-m infer -r <timestamp>` 续跑推理。
- 提供 OpenCompass API 评测配置模板，默认固定 `gsm8k`、`math-500`、`openai_humaneval`，只替换模型和服务相关字段。
- 支持多模型、多数据集、多波次计划表，长队列可由后台 `auto_test_orchestrator.py` 跨会话推进。
- 长队列任务结束后默认停止容器释放 DCU 资源，同时保留 stopped 容器便于排查。
- 测试完成后按 `<模型, 数据集>` 汇总指标、异常、日志路径和输出目录。

## 目录结构

```text
dcu-llmtest-pipeline/
  SKILL.md                                      # Codex skill 入口，包含触发条件、模式选择、核心约束和引用导航
  README.md                                    # GitHub 展示页，说明能力、安装方式、目录结构和常用流程
  DEVELOPMENT_LOG.md                          # 开发日志，记录各版本变更、修复点和发布说明
  references/
    current_version.md                         # 当前版本能力、边界和维护说明
    service_workflow.md                        # vLLM/SGLang 服务脚本生成、启动和 ready 监控流程
    accuracy_workflow.md                       # evalscope/OpenCompass 精度测试、续跑、监控和结果提取流程
    auto_test_plan.md                          # 多模型、多波次、长队列计划表和 orchestrator 执行规范
    model_deployment_cookbook.md               # HYGON-AI cookbook-first 的模型部署方案索引规则
    vllm_test_guidance.md                      # 本地 vLLM 测试指导的读取和筛选规则
    VLLM测试指导.md                            # 本地 vLLM 补充方案资料，含模型、卡型和启动建议
    sglang_test_guidance.md                    # 本地 SGLang 测试指导的读取、脱敏占位和筛选规则
    SGLANG测试指导.md                          # 本地 SGLang 补充方案资料，已脱敏
    opencompass_config_template.md             # OpenCompass API 评测配置模板，默认固化常用数据集
    accuracy_report_template.md                # 正式精度报告字段和输出模板
    container/
      create_docker_container.md               # DCU Docker 容器创建、挂载、命名和释放规则
    evaluation_framework/
      install_evaluation_framework.md          # evalscope/OpenCompass 安装、固定依赖安装和验证规则
    node/
      nodes.md                                 # DCU 节点、IP、卡型和资源查询命令清单
    rules/
      dcu_adaptation_rules.md                  # DCU 推理服务适配规则，覆盖环境变量、端口和日志约束
  scripts/
    auto_test_orchestrator.py                  # 后台任务编排器，推进队列、写状态/事件、终态释放资源
    update_cookbook_cache.py                   # HYGON-AI cookbook 稀疏缓存检查、更新和状态记录
    eval_accuracy.sh                           # evalscope 精度测试启动脚本
    watch_accuracy.sh                          # 精度任务 watcher，检查日志、prediction 和异常状态
    watch_llm_ready.sh                         # 通用 vLLM/SGLang 服务 ready watcher
    watch_vllm_ready.sh                        # 兼容旧流程的 vLLM ready watcher
```

## 安装

将本目录放到 Codex skills 目录：

```bash
mkdir -p ~/.codex/skills
cp -a dcu-llmtest-pipeline ~/.codex/skills/
```

如果使用自定义 `CODEX_HOME`：

```bash
mkdir -p "$CODEX_HOME/skills"
cp -a dcu-llmtest-pipeline "$CODEX_HOME/skills/"
```

## 触发方式

当用户提到以下任务时，Codex 应使用本 skill：

- 模型推理
- 性能测试
- 精度测试
- 继续评估、补评估、续跑
- 批量测试、多个模型
- 计划表、长队列后台执行

## 工作模式

### 通用完整流程

适合单模型或少量模型：

1. 查询可用节点资源。
2. 创建或复用容器。
3. 生成或校验 vLLM/SGLang 服务脚本。
4. 启动服务并等待 watcher 确认 ready。
5. 执行精度测试或用户提供的性能测试。
6. 汇总结果和日志路径。

### 高自定义流程

适合用户已经提供启动脚本、容器、评测命令或特殊参数的任务。Skill 会保留用户逻辑，同时校验模型路径、卡型、端口、数据集挂载、依赖和日志路径。

### 多模型自动计划

适合多模型、多数据集、多波次或预计跨小时/跨天的长队列任务。执行前必须生成计划表并等待用户确认，确认后由后台 orchestrator 推进。

## OpenCompass 续跑

评测阶段失败但已有 prediction/result 时：

```bash
opencompass <OpenCompass配置> -m eval -r <timestamp> -w <work_dir>
```

推理阶段中断或需要补齐 prediction 时：

```bash
opencompass <OpenCompass配置> -m infer -r <timestamp> -w <work_dir>
```

OpenCompass 常用评测依赖固定安装：

```bash
pip install math_verify latex2sympy2_extended antlr4-python3-runtime human-eval \
  -i https://pypi.tuna.tsinghua.edu.cn/simple
```

## 版本说明

- 当前能力和边界：`references/current_version.md`
- 变更历史：`DEVELOPMENT_LOG.md`

## 注意事项

- 本 skill 默认只处理 vLLM 和 SGLang 服务。
- 模型宿主机路径必须由用户提供，不自动猜测。
- 精度测试数据集默认宿主机路径为 `/public/home/wanghy18/opencompass/data`。
- 长队列执行不依赖 Agent 会话保持在线，但后台 watcher/orchestrator 不能主动唤醒聊天会话；用户回来后读取状态文件和报告草稿即可补发总结。
