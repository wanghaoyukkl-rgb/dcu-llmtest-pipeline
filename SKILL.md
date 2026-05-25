---
name: dcu-llmtest-pipeline
description: DCU模型推理全流程自动化工具。目前支持模式：1)通用完整流程模式(查找可用资源→生成脚本→推理→数据整理)；2)高自定义模式（查找可用资源→配置环境→根据提供的脚本和参数来进行推理和汇报）；3)多模型自动计划模式（查找节点资源→收集模型/卡型/测试类型→查询启动资源需求→生成并确认并行/串行计划表→后台orchestrator跨会话执行）。当用户提到"模型推理"、"性能测试"、"精度测试"、"继续评估"、"续跑"、"批量测试"、"多个模型"、"计划表"时使用此skill。
version: "0.6.0-alpha"
---

# DCU 推理全流程 Skill

当前版本：**v0.6.0-alpha**。版本特性和边界见 `references/current_version.md`，仅在用户询问版本能力或维护 skill 时读取。

本 skill 负责 DCU LLM 推理/精度测试工作流。主文件只保留入口、核心约束和引用导航；执行细节按需读取 references，避免一次性加载过多上下文。

## 先判断模式

如果用户已经明确给出目标和执行方式，直接进入对应模式；否则先让用户选择：

1. **通用完整流程**：查找可用资源 -> 生成/校验脚本 -> 启动推理服务 -> 执行测试 -> 汇总报告。
2. **高自定义**：用户提供脚本、参数或部分流程，由 Agent 做环境配置、校验、执行和汇报。
3. **多模型自动计划**：多模型/多节点/长队列，先生成计划表，用户确认后启动后台 orchestrator 跨会话推进。

## 按需读取

| 场景 | 必读引用 |
|------|----------|
| 了解当前版本能力和边界 | `references/current_version.md` |
| 查询可用节点、卡型、IP | `references/node/nodes.md` |
| 创建/复用 DCU 容器 | `references/container/create_docker_container.md` |
| 生成或校验 vLLM/SGLang 服务脚本 | `references/service_workflow.md`、`references/model_deployment_cookbook.md` |
| cookbook 未覆盖且框架为 vLLM | `references/vllm_test_guidance.md`、`references/VLLM测试指导.md` |
| 精度测试、继续评估、OpenCompass 续跑 | `references/accuracy_workflow.md`、`references/evaluation_framework/install_evaluation_framework.md` |
| 多模型、多波次、长时间队列 | `references/auto_test_plan.md` |
| 正式精度报告格式 | `references/accuracy_report_template.md` |
| DCU 底层适配规则 | `references/rules/dcu_adaptation_rules.md` |

不要批量读取整个 `references/`。只加载当前任务需要的文件；长引用优先用 `rg` 定位再读局部。

## 通用执行骨架

1. 收集用户需求：模型、框架、测试类型、节点/卡型、镜像、模型路径、数据集路径、是否批量、是否允许后台长跑。
2. 查询资源：从 `references/node/nodes.md` 读取节点清单，用 `hy-smi`、端口查询和进程信息整理资源表。
3. 判断是否进入自动计划：多个模型、多波次、或预计跨小时/跨天时，读取 `references/auto_test_plan.md`，先给计划表，用户确认前不得创建容器、启动服务或执行测试。
4. 创建或复用容器：读取 `references/container/create_docker_container.md`；模型路径统一挂载到 `/model/<模型名>`。
5. 启动推理服务：读取 `references/service_workflow.md`；必须 cookbook-first，服务 ready 后才能测试。
6. 执行精度/性能测试：精度读取 `references/accuracy_workflow.md`；性能当前仍按用户提供脚本或高自定义流程执行。
7. 汇总结果：短任务由 Agent 读取 watcher 状态并报告；长队列由 orchestrator 写 `state.json/events.log/reports/`，Agent 被唤醒后补发总结。

## 核心约束

- 默认只支持 vLLM 和 SGLang 服务；框架不明确时先确认。
- 容器必须后台创建，使用 `docker run -itd`，不要使用交互式前台 `docker run -it`。
- 模型宿主机路径由用户提供，不要猜测；容器内模型路径固定为 `/model/<模型名>`。
- 包含精度测试时，数据集默认宿主机路径为 `/public/home/wanghy18/opencompass/data`，容器内挂载为 `/mnt/opencompass/data:ro`；目标节点缺失时向用户索要路径。
- 生成服务脚本时必须优先参考 HYGON-AI cookbook；卡型、卡数、框架和部署模式不匹配时标记 blocked 或询问用户提供适配脚本。
- 默认 IFB 部署；只有用户明确要求 PD 分离模式时才选择 PD。
- 启动命令不得删除 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量。
- 端口必须在计划内唯一；执行时发现占用必须重新分配并同步更新计划和脚本。
- 服务就绪以 watcher 写出的状态 JSON 和 HTTP 探活为准；不要反复读取完整日志。
- 精度测试启动前必须检查评测工具环境。OpenCompass 正式评测需确认 `opencompass`、`openai`、`math_verify`、`latex2sympy2_extended`、`human_eval`。
- 用户要求“继续评估/补评估/续跑”时，优先读取 `references/accuracy_workflow.md`，按 OpenCompass `-m eval -r <timestamp>` 或 `-m infer -r <timestamp>` 处理。
- prediction 早期检查每个模型只执行一次；默认启动 600 秒后读取前 3 条有文本样本，3 条均疑似乱码时中断当前模型任务并释放资源。
- 失败任务默认释放当前服务/评测进程并继续后续队列；容器默认保留，除非用户要求清理。

## 模式一：通用完整流程

适用于单模型或少量模型的常规推理/精度测试。

流程：

1. 查询节点资源并向用户返回资源表。
2. 确认模型路径、镜像、框架、卡型、卡数、端口、测试类型和数据集路径。
3. 创建或复用容器，确保模型和数据集挂载路径符合核心约束。
4. 读取 `references/service_workflow.md`，生成/校验服务脚本并启动 watcher。
5. 服务 `ready` 后执行测试；精度测试读取 `references/accuracy_workflow.md`。
6. 测试完成后提取 summary/log/result，按 `<模型, 数据集>` 汇总。

## 模式二：高自定义

适用于用户已提供启动脚本、评测命令、特定容器或特殊参数的场景。

执行原则：

- 先理解用户提供的脚本和参数，不擅自重写核心逻辑。
- 仍要校验模型路径、端口、卡型、环境变量、数据集挂载、评测依赖和日志路径。
- 若脚本与 cookbook 或当前卡型明显冲突，展示差异并询问是否调整。
- 执行后按相同 watcher/status/report 机制汇报结果。

## 模式三：多模型自动计划

当用户提出多个模型、批量测试、多个节点并行/串行、生成计划表、长时间无人值守等需求时，必须读取 `references/auto_test_plan.md`。

必须遵守：

- 先查资源并输出节点资源表。
- 收集模型列表、框架、测试类型、数据集队列、目标卡型、部署模式、宿主模型路径、数据集路径和特殊脚本。
- 查询 cookbook 或本地补充来源，得到每个模型的卡型/卡数/TP/PP/DP/部署模式需求。
- 编排并行/串行计划表；一个节点默认 8 张卡，不考虑单模型跨节点。
- 计划表必须包含任务 ID、波次、模型、框架、测试类型、数据集队列、节点、卡数、卡 ID、端口、容器名、模型路径、状态、释放命令和 prediction 检查策略。
- 用户确认计划前不得创建容器、启动服务或执行测试。
- 计划跨小时/跨天时，必须落盘 `plan.json/state.json/events.log/reports/` 并启动 `scripts/auto_test_orchestrator.py`。

## 汇报规则

- 状态更新优先读小型 JSON：`/tmp/llm_status.json`、`/tmp/eval_status.json`、`state.json`。
- 只有失败排查或用户明确要求时才读取少量日志上下文。
- 测试完成后自动汇总结果；正式报告格式读取 `references/accuracy_report_template.md`。
- 若当前 Agent 会话结束，后台 watcher/orchestrator 只能写状态和报告文件，不能主动唤醒聊天；用户回来后读取状态文件补发报告。
