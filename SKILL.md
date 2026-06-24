---
name: dcu-llmtest-pipeline
description: DCU模型推理全流程自动化工具。目前支持模式：1)通用完整流程模式(查找可用资源→生成脚本→推理→数据整理)；2)高自定义模式（查找可用资源→配置环境→根据提供的脚本和参数来进行推理和汇报）；3)多模型计划模式（查找节点资源→收集模型/卡型/测试类型→查询启动资源需求→生成并确认并行/串行计划表→会话内目标闭环调度）。当用户提到"模型推理"、"性能测试"、"精度测试"、"继续评估"、"续跑"、"批量测试"、"多个模型"、"计划表"或"@goal"时使用此skill。
---

# DCU 推理全流程 Skill

当前版本：**v0.7.2-watch-queue-cleanup**。版本特性和边界见 `references/current_version.md`，仅在用户询问版本能力或维护 skill 时读取。

本 skill 负责 DCU LLM 推理/精度测试工作流。主文件只保留入口、核心约束和引用导航；执行细节按需读取 references，避免一次性加载过多上下文。

## 先判断模式

如果用户已经明确给出目标和执行方式，直接进入对应模式；否则先让用户选择：

1. **通用完整流程**：查找可用资源 -> 生成/校验脚本 -> 启动推理服务 -> 执行测试 -> 汇总报告。
2. **高自定义**：用户提供脚本、参数或部分流程，由 Agent 做环境配置、校验、执行和汇报。
3. **多模型计划**：多模型/多节点/长队列，先生成计划表；用户确认后使用会话内目标闭环调度推进到终态。

## 按需读取

| 场景 | 必读引用 |
|------|----------|
| 了解当前版本能力和边界 | `references/current_version.md` |
| 查询可用节点、卡型、IP | `references/node/nodes.md` |
| 创建/复用 DCU 容器 | `references/container/create_docker_container.md` |
| 生成或校验 vLLM/SGLang 服务脚本 | `references/service_workflow.md`、`references/model_deployment_cookbook.md` |
| 检查或强制更新 HYGON-AI cookbook | `references/model_deployment_cookbook.md` |
| cookbook 未覆盖且框架为 vLLM | `references/vllm_test_guidance.md`、`references/VLLM测试指导.md` |
| cookbook 未覆盖且框架为 SGLang | `references/sglang_test_guidance.md`、`references/SGLANG测试指导.md` |
| 精度测试、继续评估、OpenCompass 续跑 | `references/accuracy_workflow.md`、`references/evaluation_framework/install_evaluation_framework.md` |
| 生成 OpenCompass API 评测配置 | `references/opencompass_config_template.md` |
| 多模型、多波次、长时间队列 | `references/auto_test_plan.md` |
| 正式精度报告格式 | `references/accuracy_report_template.md` |
| DCU 底层适配规则 | `references/rules/dcu_adaptation_rules.md` |

不要批量读取整个 `references/`。只加载当前任务需要的文件；长引用优先用 `rg` 定位再读局部。

## 通用执行骨架

1. 收集用户需求：模型、框架、测试类型、节点/卡型、镜像、模型路径、数据集路径、是否批量、是否允许后台长跑。
2. 查询资源：从 `references/node/nodes.md` 读取节点清单，用 `hy-smi`、端口查询和进程信息整理资源表。
3. 判断是否进入多模型计划或目标模式：多个模型、多波次、预计跨小时/跨天、或用户给出 `@goal`/明确终态时，读取 `references/auto_test_plan.md`，先给计划表，用户确认前不得创建容器、启动服务或执行测试；不得启动旧后台编排脚本。
4. 创建或复用容器：读取 `references/container/create_docker_container.md`；模型目录通常位于目标节点 `/public/opendas/DL_DATA/llm-models/`，生成服务脚本时优先使用节点可见的模型绝对路径。
5. 启动推理服务：读取 `references/service_workflow.md`；必须 cookbook-first，服务 ready 后才能测试。
6. 执行精度/性能测试：精度读取 `references/accuracy_workflow.md`；性能当前仍按用户提供脚本或高自定义流程执行。
7. 汇总结果：仅生成 `reports/test_report.md` 作为唯一测试报告；`reports/task_plan.md` 可作为人工计划表。不得再生成重复摘要报告或旧 JSON 状态文件。

## 核心约束

- 默认只支持 vLLM 和 SGLang 服务；框架不明确时先确认。
- 任何 `pip install` 默认必须加清华源：`-i https://pypi.tuna.tsinghua.edu.cn/simple`。不要先用默认源试错；仅用户明确指定其他源时例外。
- 容器必须后台创建，使用 `docker run -itd`，不要使用交互式前台 `docker run -it`。
- 模型路径优先由用户提供；用户未提供时，先在目标节点 `/public/opendas/DL_DATA/llm-models/` 下查找同名或近似模型目录，允许该目录是软链接并解析到 `/public4/...` 等实际存储路径。生成服务启动脚本时优先使用 `/public/opendas/DL_DATA/llm-models/...` 这一类节点绝对路径；`readlink -f` 仅用于校验和记录真实落点，不强制把脚本中的模型路径改成软链接目标。
- 包含精度测试时，数据集默认宿主机路径为 `/public/home/wanghy18/opencompass/data`，容器内挂载为 `/mnt/opencompass/data:ro`；目标节点缺失时向用户索要路径。
- 生成服务脚本时必须优先参考 HYGON-AI cookbook；匹配条目必须同时对齐模型名、框架、卡型、卡数、部署模式和量化/模型变体等关键字段。模型名匹配先做规范化精确匹配；若未命中，可按 `references/model_deployment_cookbook.md` 的“模型名受控模糊匹配”生成候选并询问用户确认。不得把 cookbook 的一个条目和本地测试指导的另一个条目混合使用；同一个脚本只能有一个方案来源。卡型、卡数、框架、部署模式或模型变体不匹配时标记 blocked 或询问用户提供适配脚本。
- 自动生成或改写服务脚本时，只允许做三类适配：添加/设置 `HIP_VISIBLE_DEVICES`、把来源命令中的模型路径替换为目标节点绝对模型路径、以及为避免端口冲突或支持同节点并发而新增/修改服务监听端口。端口适配必须同步更新启动脚本、curl 探活端口、`probe_url` 和评测 API base。除此之外不得新增或修改来源方案中的环境变量、dtype、TP/PP/DP、量化参数、`-cc`/编译配置、调度参数、上下文长度、显存比例等测试设置。生成脚本不得加入或保留 `rm`、`rm -rf`、`rmdir` 等清理命令；若 cookbook 来源包含这些命令，省略并在脚本元信息或计划备注中记录。若来源方案缺少当前环境必需字段，标记 blocked/异常并询问用户，不自动试配。
- 若 cookbook 未找到规范化精确匹配，先列出 cookbook 受控模糊匹配候选并询问用户是否使用；用户确认某个候选后，该候选可作为本任务的唯一 cookbook 来源。若用户否认所有候选或 cookbook 无合理候选，才能查本地测试指导；若本地测试指导也没有精确匹配，直接反馈缺少参考脚本并询问用户是否提供。用户无法提供时，该任务跳过或标记 blocked，不要参考邻近模型、相似版本或历史脚本拼接生成。
- 读取 HYGON-AI cookbook 前必须按 `references/model_deployment_cookbook.md` 执行 cookbook 缓存检查：默认 3 天 TTL，超过 3 天或用户要求更新时在 skill 根目录运行 `python3 scripts/update_cookbook_cache.py --check` 或 `--force`。
- 默认 IFB 部署；只有用户明确要求 PD 分离模式时才选择 PD。
- 启动命令不得删除 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量。
- 端口优先按来源脚本保留；若来源脚本未指定端口则使用框架默认端口。执行前发现端口占用或同波次端口冲突时，可以自主选择目标节点上的空闲端口并同步改写脚本和计划；端口改动必须记录在脚本元信息、计划说明和报告备注中。
- 多模型计划必须优先并发利用空闲卡：若同一节点空闲卡数足够容纳多个任务，必须把这些任务放入同一波次，并为每个任务分配互不重叠的 `cards` 和互不冲突的 `port`。不得因为默认卡 ID、默认端口或保守排序把可并发的独立任务串行化。
- 服务启动日志必须落盘到当前 `<run_dir>/serve_logs/`，例如 `<run_dir>/serve_logs/<task_id>.serve.log`。
- 模型服务监控使用一次性脚本 `scripts/watch_model_once.sh`：服务启动阶段每 2 分钟调用一次 `serve`，只读 `<run_dir>/serve_logs/<task_id>.serve.log` 最后 10 行并做 HTTP 探活；精度阶段每 20 分钟调用一次 `accuracy`，只读 OpenCompass `logs/infer`、`logs/eval` 最后 10 行，若存在 `summary/` 则连带读取 summary。不得使用旧 `watch_*` 脚本或旧后台编排逻辑。
- 精度测试启动前必须按 `references/evaluation_framework/install_evaluation_framework.md` 检查并准备评测工具环境。除非用户明确指定使用本地现有 OpenCompass 工程，否则 OpenCompass 源码必须 clone 到容器内 `/workspace/opencompass` 并在容器内安装；不得临时从宿主机查找或挂载 `/public/home/wanghy18/opencompass` 作为默认工程来源。数据集仍固定挂载到 `/mnt/opencompass/data:ro`。
- 默认在模型服务容器内安装并运行评测工具；只有用户明确要求隔离评测容器，或服务容器不允许安装评测依赖时，才允许规划独立 eval 容器。独立 eval 容器必须提前写入计划和报告，不能作为服务 ready 后的隐式补救动作。
- OpenCompass 正式评测和续跑前，直接用清华源安装常用评测依赖 `math_verify latex2sympy2_extended antlr4-python3-runtime human-eval`，不要先逐个 import 检查这些依赖；仍需确认 `opencompass`/`openai` 或 `/workspace/opencompass/run.py` 可用。
- OpenCompass API 评测配置默认使用 `references/opencompass_config_template.md`。除非用户明确要求，数据集固定为 `gsm8k`、`math-500`、`openai_humaneval`，只替换 `openai_api_base`、`tokenizer_path`、`path`、`abbr`、`work_dir`。
- OpenCompass 启动必须优先使用 `scripts/start_opencompass_safe.sh` 或等价逐字逻辑：宿主机只创建宿主机 `<RUN_DIR>` 下目录，容器内 `/mnt/dcu-llmtest-run/...` 目录只能在 `docker exec` 内创建；`CONFIG` 和 `WORK_DIR` 必须使用容器路径；启动前必须校验配置存在、`/workspace/opencompass/run.py` 或已安装 `opencompass` runner 可导入，启动后必须确认 OpenCompass 进程仍在。不得在宿主机执行 `mkdir -p /mnt/dcu-llmtest-run/...`。若遇到类似本次 OpenCompass config/import/plugin 启动问题，则在容器内建立 `/usr/local/lib/python3.10/dist-packages/autotest/configs -> /workspace/opencompass/opencompass/configs` 软链接，并用 `VLLM_PLUGINS="" python /workspace/opencompass/run.py <config>.py --debug` 兜底启动；兜底启动仍必须记录配置、work_dir、PID/log、summary 路径并继续更新计划表。
- 用户要求“继续评估/补评估/续跑”时，优先读取 `references/accuracy_workflow.md`，按 OpenCompass `-m eval -r <timestamp>` 或 `-m infer -r <timestamp>` 处理。
- 服务启动脚本检测到启动错误时，立即将该任务标记为 `异常`，记录错误摘要并释放当前资源；不得自动修改参数、切换 dtype/量化/编译配置、删减环境变量、换 cookbook 条目或进行其它试错重启。只有用户明确提供新脚本或明确授权修改后，才允许重新计划该任务。
- 模型服务 `ready` 后、精度测试启动前，必须用 `/v1/chat/completions` 执行一次 curl 样本请求；curl 只是服务可用性门禁，响应正常且无乱码后必须继续执行 `eval_start_cmd` 对应的精度/性能测试，不能把 curl 通过当作任务完成。除非用户明确要求只做服务探活，默认模型测试/精度测试使用 OpenCompass 正式评测，不得用 `mark_done.sh` 代替评测。
- 每次执行任务必须先生成并持续更新 `reports/test_report.md` 和 `reports/task_plan.md`；`test_report.md` 是唯一测试报告，任务计划表表头固定为 `模型/测试工具/加速卡型号/加速卡信息/所需卡数/KVCache/状态/时间戳`。`KVCache` 根据服务启动命令判断：包含 `--kv-cache-dtype fp8...` 时填 `kvcache_fp8`，否则填 `default`。
- 任务计划表状态只允许四种：`待测试`、`测试中`、`通过`、`异常`；动态调度时允许更新 `加速卡信息`、`所需卡数`、`状态` 和 `时间戳`，普通进度更新只改状态栏和时间戳。
- 旧 evalscope/OpenCompass 监控和后台编排逻辑已移除；不得生成旧 JSON 状态文件、旧后台日志或重复摘要报告。
- 用户给出明确终态目标或 `@goal [...]` 时进入目标模式：同一会话内持续推进计划、启动、watch、curl、OpenCompass、报告、释放和待测模型补充调度，直到所有任务进入 `通过` 或 `异常`。
- 单个任务终态后默认立即 `docker stop <container>` 释放 DCU 显存和进程；只有用户明确要求“保持服务/容器运行”时才不停止。若目标模式下仍有 `待测试` 任务，释放后立即扫描 `reports/task_plan.md`，只在加速卡型号匹配且空闲卡数满足 `所需卡数` 时分配卡和端口并启动下一项。
- 失败任务默认释放当前服务/容器并继续后续队列；容器在队列运行期间可保持 stopped 状态便于排障。所有任务均进入 `通过` 或 `异常` 后，对本轮 skill 管理的测试容器执行 `docker stop` 后再 `docker rm` 删除。

## 模式一：通用完整流程

适用于单模型或少量模型的常规推理/精度测试。

流程：

1. 查询节点资源并向用户返回资源表。
2. 确认模型路径、镜像、框架、卡型、卡数、端口、测试类型和数据集路径。
3. 创建或复用容器，确保模型和数据集挂载路径符合核心约束。
4. 读取 `references/service_workflow.md`，生成/校验服务脚本，并使用 `scripts/watch_model_once.sh serve ...` 观察服务启动。
5. 服务 `ready` 后执行测试；精度测试读取 `references/accuracy_workflow.md`。
6. 测试完成后提取 summary/log/result，按 `<模型, 数据集>` 汇总。

## 模式二：高自定义

适用于用户已提供启动脚本、评测命令、特定容器或特殊参数的场景。

执行原则：

- 先理解用户提供的脚本和参数，不擅自重写核心逻辑。
- 仍要校验模型路径、端口、卡型、环境变量、数据集挂载、评测依赖和日志路径。
- 若脚本与 cookbook 或当前卡型明显冲突，展示差异并询问是否调整。
- 执行后按 `reports/test_report.md` 和 `reports/task_plan.md` 汇报结果，终态后默认停止该任务容器释放资源。

## 模式三：多模型计划

当用户提出多个模型、批量测试、多个节点并行/串行、生成计划表、长时间无人值守等需求时，必须读取 `references/auto_test_plan.md`。

必须遵守：

- 先查资源并输出节点资源表。
- 收集模型列表、框架、测试类型、数据集队列、目标卡型、部署模式、宿主模型路径、数据集路径和特殊脚本。
- 查询 cookbook 或本地补充来源，得到每个模型的卡型/卡数/TP/PP/DP/部署模式需求。
- 编排并行/串行计划表；一个节点默认 8 张卡，不考虑单模型跨节点。
- 当同节点空闲卡数足够时，优先生成并行波次；例如 8 张空闲 BW1100 上有 4 个单卡模型时，必须同一波次分配 `cards=0,1,2,3` 和不同服务端口并发执行。
- 执行计划必须能生成 `reports/task_plan.md`，表头固定为 `模型、测试工具、加速卡型号、加速卡信息、所需卡数、KVCache、状态、时间戳`。
- 用户确认计划前不得创建容器、启动服务或执行测试。
- 多模型、长时间任务和排队任务在目标模式下使用会话内闭环推进；某模型完成或异常后立即释放资源，扫描 `待测试` 任务，只有加速卡型号匹配且空闲卡满足 `所需卡数` 时才立即分配卡和端口并启动下一个任务。不得调用旧后台编排脚本或生成旧状态文件。

## 汇报规则

- 状态更新优先读 `reports/task_plan.md`；结果概要读 `reports/test_report.md`。旧 JSON 状态文件和后台事件文件已移除。
- 只有失败排查或用户明确要求时才读取少量日志上下文。
- 测试执行中持续更新 `reports/task_plan.md` 和 `reports/test_report.md`；测试完成后自动汇总结果。正式报告格式读取 `references/accuracy_report_template.md`。
- 当前版本不提供后台跨会话监控；目标模式只在当前会话内推进闭环，调度状态以 `reports/task_plan.md` 为准。
