# dcu-llmtest-pipeline

DCU 模型推理全流程自动化 Skill，用于协助完成大模型推理测试中的资源查询、容器创建、服务启动、就绪监控、精度评测和结果汇总。

当前版本：`v0.5.5-alpha`

## 适用场景

- 在 DCU 节点上启动 vLLM 或 SGLang 推理服务。
- 根据 HYGON-AI `dcu-inference-cookbook` 最佳实践生成或校验模型服务脚本。
- 对多个模型生成并行/串行测试计划表，并在用户确认后按波次执行。
- 监控模型服务启动状态，避免反复读取完整日志造成上下文浪费。
- 使用 `evalscope` 或 `opencompass` 执行精度测试并整理报告。

## 工作模式

Skill 当前支持三种入口：

1. **通用完整流程**：查找可用资源 -> 生成脚本 -> 启动推理 -> 数据整理。
2. **高自定义流程**：查找资源 -> 配置环境 -> 按用户提供的脚本和参数执行测试。
3. **多模型自动计划模式**：查找节点资源 -> 收集模型/卡型/测试类型 -> 查询资源需求 -> 生成计划表 -> 用户确认后执行。

## 当前核心约定

### 模型路径

无论使用 vLLM 还是 SGLang，服务启动命令中的模型路径统一为：

```text
/model/<模型名>
```

创建容器前需要用户提供目标节点上的宿主机模型目录。容器创建时按只读方式挂载：

```text
-v <宿主机模型目录>:/model/<模型名>:ro
```

不要把宿主机模型路径直接写入 vLLM/SGLang 启动命令。

### 容器创建

容器创建必须使用后台模式：

```bash
docker run -itd
```

容器命名格式为：

```text
<加速卡型号>-<YYYYMMDD>-<模型名>-<框架名>
```

例如：

```text
BW1100-20260522-Qwen3-32B-vllm
```

### 服务监控

服务启动后使用 `scripts/watch_llm_ready.sh` 进行轻量状态监控。Watcher 会写入小型 JSON 状态文件，Agent 正常只读取状态文件，失败或超时时再读取少量日志上下文。

默认探活端点包括：

```text
/health
/v1/models
/server_info
/get_server_info
```

## 目录结构

```text
.
├── SKILL.md
├── DEVELOPMENT_LOG.md
├── README.md
├── scripts/
│   ├── eval_accuracy.sh
│   ├── watch_accuracy.sh
│   ├── watch_llm_ready.sh
│   └── watch_vllm_ready.sh
└── references/
    ├── auto_test_plan.md
    ├── model_deployment_cookbook.md
    ├── vllm_test_guidance.md
    ├── VLLM测试指导.md
    ├── container/create_docker_container.md
    ├── evaluation_framework/install_evaluation_framework.md
    ├── node/nodes.md
    └── rules/dcu_adaptation_rules.md
```

## 关键文件

- `SKILL.md`：Skill 主流程、触发场景、版本特性和执行规则。
- `references/model_deployment_cookbook.md`：HYGON-AI cookbook 的 vLLM/SGLang 最佳实践索引和适配规则。
- `references/container/create_docker_container.md`：DCU 推理测试容器创建规范。
- `references/auto_test_plan.md`：多模型并行/串行计划表生成规则。
- `references/evaluation_framework/install_evaluation_framework.md`：`evalscope` 与 `opencompass` 安装方式。
- `scripts/watch_llm_ready.sh`：通用 LLM 服务就绪监控脚本。
- `scripts/eval_accuracy.sh`：基于 OpenAI-compatible API 的 evalscope 精度测试脚本。

## 使用方式

在 Codex 环境中安装或启用该 Skill 后，直接描述测试目标即可。例如：

```text
我要在 BW1100 上测试 Qwen3-32B，使用 vLLM，做精度测试。
```

或：

```text
我要测试多个模型，帮我先查找可用节点并生成并行/串行计划表。
```

对于模型服务启动，Skill 会优先参考 HYGON-AI `dcu-inference-cookbook/docs/model-deployment/` 中对应框架和模型族的最佳实践。若 cookbook 未覆盖目标模型，vLLM 可继续参考本仓库的脱敏版 `VLLM测试指导.md`；SGLang 未覆盖时会请求用户提供适配脚本。

## 当前边界

- 当前自动计划只考虑单机模型，不处理一个模型跨多个节点的场景。
- 性能测试流程仍在建设中，标准压测脚本和吞吐/延迟汇总规则尚未完整内置。
- OpenCompass 已提供安装方式和选择规则，但具体数据集配置模板仍需继续补齐。
- 节点清单、镜像选择、模型宿主路径等环境信息仍需要结合实际集群由用户确认。

## 版本日志

完整版本变化见 [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md)。
