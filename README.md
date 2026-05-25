# dcu-llmtest-pipeline

DCU LLM 推理与精度测试自动化 Codex Skill。

当前版本：`v0.6.0-alpha`

## 能力概览

- 查询 DCU 节点资源、卡型、占用、端口和驱动信息。
- 创建或复用 DCU 推理测试容器，统一模型挂载路径为 `/model/<模型名>`。
- 基于 HYGON-AI `dcu-inference-cookbook` 优先生成或校验 vLLM/SGLang 启动脚本。
- 使用 watcher 低频状态文件监控推理服务就绪，避免反复读取大日志。
- 支持 `evalscope` 与 `opencompass` 精度测试。
- 支持 OpenCompass 依赖检查、补装、`-m eval -r <timestamp>` 补评估和 `-m infer -r <timestamp>` 续跑推理。
- 支持多模型、多数据集、多波次计划表，长队列可由后台 `auto_test_orchestrator.py` 跨会话推进。
- 测试完成后按 `<模型, 数据集>` 汇总指标、异常、日志路径和输出目录。

## 目录结构

```text
dcu-llmtest-pipeline/
  SKILL.md
  DEVELOPMENT_LOG.md
  README.md
  references/
    current_version.md
    service_workflow.md
    accuracy_workflow.md
    auto_test_plan.md
    model_deployment_cookbook.md
    vllm_test_guidance.md
    VLLM测试指导.md
    accuracy_report_template.md
    container/create_docker_container.md
    evaluation_framework/install_evaluation_framework.md
    node/nodes.md
    rules/dcu_adaptation_rules.md
  scripts/
    auto_test_orchestrator.py
    eval_accuracy.sh
    watch_accuracy.sh
    watch_llm_ready.sh
    watch_vllm_ready.sh
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

常用依赖补装：

```bash
pip install math_verify latex2sympy2_extended human-eval
```

## 版本说明

- 当前能力和边界：`references/current_version.md`
- 变更历史：`DEVELOPMENT_LOG.md`

## 注意事项

- 本 skill 默认只处理 vLLM 和 SGLang 服务。
- 模型宿主机路径必须由用户提供，不自动猜测。
- 精度测试数据集默认宿主机路径为 `/public/home/wanghy18/opencompass/data`。
- 长队列执行不依赖 Agent 会话保持在线，但后台 watcher/orchestrator 不能主动唤醒聊天会话；用户回来后读取状态文件和报告草稿即可补发总结。
