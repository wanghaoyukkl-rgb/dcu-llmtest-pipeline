# dcu-llmtest-pipeline

DCU LLM 推理与精度测试自动化 Codex Skill。

当前版本：`v0.7.2-watch-queue-cleanup`

## 能力概览

- 查询 DCU 节点资源、卡型、占用、端口和驱动信息。
- 创建或复用 DCU 推理测试容器，统一模型挂载路径为 `/model/<模型名>`。
- 基于 HYGON-AI `dcu-inference-cookbook` 优先生成或校验 vLLM/SGLang 启动脚本。
- 自动维护 cookbook 本地稀疏缓存，默认 3 天检查更新一次，用户要求时可强制更新。
- cookbook 未覆盖时，可按框架读取本地脱敏版 vLLM/SGLang 测试指导作为补充来源。
- 支持 `evalscope` 与 `opencompass` 精度测试。
- 支持 OpenCompass 常用评测依赖固定安装、`-m eval -r <timestamp>` 补评估和 `-m infer -r <timestamp>` 续跑推理。
- 提供 OpenCompass API 评测配置模板，默认固定 `gsm8k`、`math-500`、`openai_humaneval`，只替换模型和服务相关字段。
- 提供 OpenCompass 安全启动脚本 `scripts/start_opencompass_safe.sh`，避免宿主机/容器路径混用。
- 提供一次性 watch 脚本 `scripts/watch_model_once.sh`，服务阶段每 2 分钟观察，精度阶段每 20 分钟观察。
- 支持生成多模型、多数据集、多波次人工计划表，并在目标模式下会话内动态补充调度；任务终态后释放资源并按计划表补充启动待测任务。
- 唯一测试报告为 `reports/test_report.md`；`reports/task_plan.md` 可作为人工计划表。

旧模型服务监控、后台编排逻辑和旧 JSON 状态文件已移除；当前只使用一次性 watch、`reports/task_plan.md` 和会话内目标闭环。

## 目录结构

```text
dcu-llmtest-pipeline/
  SKILL.md
  README.md
  DEVELOPMENT_LOG.md
  references/
    current_version.md
    service_workflow.md
    accuracy_workflow.md
    auto_test_plan.md
    model_deployment_cookbook.md
    vllm_test_guidance.md
    VLLM测试指导.md
    sglang_test_guidance.md
    SGLANG测试指导.md
    opencompass_config_template.md
    accuracy_report_template.md
    container/create_docker_container.md
    evaluation_framework/install_evaluation_framework.md
    node/nodes.md
    rules/dcu_adaptation_rules.md
  scripts/
    start_opencompass_safe.sh
    watch_model_once.sh
    update_cookbook_cache.py
    eval_accuracy.sh
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
- 计划表

## 工作模式

### 通用完整流程

适合单模型或少量模型：

1. 查询可用节点资源。
2. 创建或复用容器。
3. 生成或校验 vLLM/SGLang 服务脚本。
4. 启动服务并用 HTTP/curl 样本检查确认可用。
5. 执行精度测试或用户提供的性能测试。
6. 汇总结果和日志路径到 `reports/test_report.md`。

### 高自定义流程

适合用户已经提供启动脚本、容器、评测命令或特殊参数的任务。Skill 会保留用户逻辑，同时校验模型路径、卡型、端口、数据集挂载、依赖和日志路径。

### 多模型计划

适合多模型、多数据集、多波次任务。执行前必须生成人工计划表并等待用户确认；用户给出 `@goal` 或明确终态目标时，在当前会话内推进到所有任务 `通过/异常`。旧后台跨会话推进逻辑已移除。

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
- 当前版本不生成旧 JSON 状态文件、旧事件流水、旧后台日志或重复摘要报告。
