# 多模型自动测试计划编排

当用户提出多个模型需要测试、批量测试、多个节点并行/串行执行、生成计划表等需求时，必须先生成测试计划表，等待用户确认或修改后再开始执行。

## 适用范围

- 当前只考虑单机模型，不考虑一个模型跨多个节点。
- 默认一个节点有 8 张卡。
- 一个测试任务只绑定一个节点。
- 同一个节点可并行运行多个任务，但并行任务所需卡数之和不能超过该节点可用卡数。
- 若任务需要 8 张卡，则独占一个节点。
- 支持并行波次和串行波次：同一波次中的任务可并行启动，不同波次按顺序执行。
- 多模型、多波次、或预计跨小时/跨天的计划必须使用后台 orchestrator 执行，不能依赖 Agent 会话持续在线。

## 计划生成流程

### Step 1：查找可用节点资源

从 `references/node/nodes.md` 读取节点列表，并查询每个节点：

- 节点 IP
- 加速卡型号，例如 `BW1000`、`BW1100`、`K100_AI`
- 总卡数，默认 8
- 当前空闲卡数和空闲卡 ID
- 当前占用情况
- 已监听端口，避免端口冲突
- 驱动版本和频率信息

建议命令：

```bash
ssh <Node_IP> "/opt/hyhal/bin/hy-smi"
ssh <Node_IP> "/opt/hyhal/bin/hy-smi -c"
ssh <Node_IP> "/opt/hyhal/bin/hy-smi --showdriverversion"
ssh <Node_IP> "/opt/hyhal/bin/hy-smi --showproductname"
ssh <Node_IP> "ss -lnt 2>/dev/null | awk '{print \$4}' | sed -n '2,\$p'"
```

### Step 2：收集用户测试需求

若用户没有一次性提供完整信息，最少补齐以下字段：

- 模型列表
- 推理框架：`vllm` 或 `sglang`
- 测试类型：精度、性能、或两者都测
- 精度数据集列表和 limit；多个数据集按每个模型自己的队列执行
- 目标加速卡型号
- 部署模式：默认 `IFB`；只有用户明确要求时才使用 `PD`
- 每个模型在目标节点上的宿主机模型目录；若用户未提供，先询问用户
- 精度数据集宿主机根目录；默认 `/public/home/wanghy18/opencompass/data`，不存在时向用户索要路径
- 精度评测工具；若选择 OpenCompass，确认容器内是否可运行 `opencompass`/`openai` 或 `/mnt/opencompass/run.py`，并在启动评测前直接安装 `math_verify`、`latex2sympy2_extended`、`antlr4-python3-runtime`、`human-eval`
- 每个模型是否有指定脚本或特殊参数

可选字段：

- 优先级
- 预计测试时长
- 性能测试参数
- 是否允许同节点并行多个小模型
- OpenCompass 是否需要续跑：`-m eval -r <timestamp>` 用于已有 prediction/result 后补评估，`-m infer -r <timestamp>` 用于推理中断后补齐 prediction

### Step 3：查询模型启动资源需求

查询前先按 `references/model_deployment_cookbook.md` 在 skill 根目录执行 cookbook 缓存检查：`python3 scripts/update_cookbook_cache.py --check`；用户要求更新时执行 `--force`。状态文件中的 `last_update_utc`、`head_commit`、`head_commit_date` 应记录到计划备注或报告中，便于追踪本次计划使用的 cookbook 版本。

对每个模型，先根据 `references/model_deployment_cookbook.md` 到 HYGON-AI cookbook 中查询；若 cookbook 未覆盖，再按框架查询本地补充测试方案：`vllm` 读取 `references/vllm_test_guidance.md` 和 `references/VLLM测试指导.md`，`sglang` 读取 `references/sglang_test_guidance.md` 和 `references/SGLANG测试指导.md`。

- cookbook 文件路径
- 匹配模型条目
- 推荐加速卡型号
- 推荐卡数
- 部署方式 IFB/PD
- TP/PP/DP
- dtype
- 量化方式
- 上下文长度
- 框架版本
- 特殊环境变量和启动参数
- 来源：cookbook 文件或本地补充文档模型标题/卡型小节
- 容器内模型路径：固定为 `/model/<模型名>`

若 cookbook 和本地补充来源中目标模型/框架/卡型/部署方式都没有匹配条目：

- 标记为 `blocked: need_script`
- 询问用户是否能够提供适配当前卡型的启动脚本
- 不要将该任务自动排入执行计划

若来源条目卡型与用户目标卡型或当前节点卡型不一致：

- 标记为 `blocked: card_mismatch`
- 展示来源卡型和当前卡型差异
- 询问用户是否提供脚本或改用匹配卡型节点

本地测试指导中的卡型别名必须先规范化：`NMZ` -> `BW1100/BW1101`，`BMZ` -> `BW1000`，`KME`/`K100`/`K100_AI` -> `K100AI`。SGLang 补充文档中出现 `<HOST_IP>`、`<LOCAL_PATH>`、`[internal-link-removed]` 时，不要原样排入计划；必须替换为当前环境值，无法替换则标记 blocked。

### Step 4：端口分配

端口不能重复。计划中所有任务必须分配唯一端口，即使任务位于不同节点，也优先保持全局唯一，方便排查和报告。

默认端口池：

- vLLM：`8000-8099`
- SGLang：`30000-30099`

分配规则：

1. 先收集所有目标节点已监听端口。
2. 从框架默认端口池中选择未被占用且计划内未使用的端口。
3. 若默认端口已占用，向后递增。
4. 若启动脚本中已有端口参数，执行前必须改写为计划分配端口。
5. 每个任务的 watcher 使用同一个端口探活。

### Step 4.1：模型路径与容器命名

每个任务必须在计划中固定模型路径和容器名：

- 宿主模型路径：来自用户提供的目标节点路径。
- 容器模型路径：固定为 `/model/<模型名>`。
- 容器挂载：`-v <宿主模型路径>:/model/<模型名>:ro`。
- 容器名：`<加速卡型号>-<YYYYMMDD>-<模型名>-<框架名>`，必要时将模型名中的 `/` 和空格替换为 `-`。

无论后续启动 vLLM 还是 SGLang，启动命令中的 model path 都必须使用计划表中的容器模型路径。

### Step 5：计划编排算法

使用保守的 First-Fit Decreasing 规则：

1. 过滤掉 blocked 任务。
2. 按所需卡数从大到小排序。
3. 只在卡型匹配的节点中放置任务。
4. 优先放入当前最早可用且剩余卡数足够的节点波次。
5. 如果当前波次放不下，就在该节点创建下一波次。
6. 同一节点同一波次任务可并行启动；下一波次必须等待上一波次任务完成并清理资源。
7. 任务需要 8 卡时独占节点当前波次。

不要跨节点拆分单个模型。

### Step 5.1：多模型多数据集执行队列

当一个计划包含多个模型和多个精度数据集时，调度粒度必须区分“模型服务”和“数据集评测子任务”：

- 模型服务任务占用加速卡资源；数据集评测子任务复用该模型服务。
- 每个模型维护自己的数据集队列，例如 `gsm8k -> math_500 -> humaneval`。
- 某个模型完成当前数据集后，立即启动该模型的下一个数据集；不要等待其他模型完成同一数据集。
- 某个模型完成全部数据集后，才能按用户确认释放模型服务和加速卡资源；容器可按用户要求保留。
- 执行前必须生成 `reports/test_report.md` 和 `reports/task_plan.md`；任务计划表按确认后的计划执行，状态更新只改状态栏和时间戳。
- 每个模型服务 `ready` 后、评测启动前必须执行一次 curl 样本请求。响应正常且无乱码才启动评测；请求失败或疑似乱码时，在 `reports/task_plan.md` 中标记为 `异常`，释放该模型资源，不影响其他模型继续执行。

### Step 5.2：后台 orchestrator 执行规范

当计划满足任一条件时，必须生成后台执行计划并启动 orchestrator：

- 模型数大于 1，或存在串行/多波次排队。
- 预计总耗时超过当前 Agent 会话可持续时间。
- 用户明确要求“自动排队”“跑完一个继续下一个”“长时间任务无人值守”。

落盘结构：

```text
<run_dir>/
  plan.json
  state.json
  events.log
  orchestrator.log
  reports/
    task_plan.md
    test_report.md
  task_<ID>/
```

`plan.json` 中每个任务至少包含：

- `task_id`、`wave`、`model`、`framework`、`node`、`cards`、`container`、`port`
- `start_cmd`：启动该模型服务的宿主机命令，必须可由 orchestrator 后台执行
- `service_status_file`：模型服务 watcher 写出的状态 JSON，例如 `/tmp/llm_status.json`
- `eval_start_cmd`：curl 样本检查通过后启动精度评测的宿主机命令
- `status_file`：统一 watcher 写出的状态 JSON
- `log_file`：主要评测日志；无外层日志时填 `none`
- `summary_glob`、`done_file` 或 `completion_check_cmd`：统一 watcher 完成判断来源，evalscope/OpenCompass 都按这套字段配置
- `probe_url`：curl 样本检查 URL；默认 `http://127.0.0.1:<port>/v1/chat/completions`
- `served_model_path`：curl 请求体中的 `model` 字段，默认 `/model/<模型名>`
- `release_cmd`：释放该模型评测/服务资源的命令；默认 `docker stop <container>`，容器 stopped 保留
- `output_dir`：summary、prediction、日志所在目录
- `test_tool`：`evalscope` 或 `opencompass`
- `accelerator`：加速卡型号，用于 `reports/task_plan.md`
- `release_on_done`：默认 `true`；只有用户明确要求保持服务时才设为 `false`
- 若使用 OpenCompass，额外记录 `opencompass_config`、`work_dir`、`run_timestamp`、`summary_glob`、`resume_eval_cmd`、`resume_infer_cmd`

`plan.json` 顶层 watch 间隔：

- 短任务默认 `watch_interval_sec=600`。
- 长时间任务默认 `watch_interval_sec=1800` 或 `watch_mode=long`。
- 用户要求手动查询时，仍启动后台 orchestrator，但汇报时只读取 `reports/task_plan.md`、`state.json` 和 `events.log`。

orchestrator 行为要求：

1. 启动后读取 `plan.json`，初始化或恢复 `state.json`。
2. 根据计划资源字段调度 pending 任务；同一节点同一卡 ID 不得被两个 running 任务同时占用。
3. 任务启动、完成、失败、中断、释放资源都必须追加到 `events.log`，并同步输出到 `orchestrator.log`。
4. 启动前写入 `reports/task_plan.md` 和 `reports/test_report.md`；任务计划表表头固定为 `模型/测试工具/加速卡型号/状态/时间戳`。
5. `reports/task_plan.md` 的状态只使用 `待测试`、`测试中`、`通过`、`异常`；后续任务启动、异常、完成等节点只更新状态栏和时间戳。
6. 任务 `start_cmd` 返回 0 后等待 `service_status_file` 为 `ready`，随后执行 curl 样本请求：`/v1/chat/completions`、提示词“介绍一下人工智能发展史”、`max_tokens=500`、`temperature=0.0`。
7. curl 响应正常且无乱码后才执行 `eval_start_cmd`；curl 请求失败、响应为空、非 JSON 或疑似乱码时，标记为 `异常`，执行 `release_cmd`，然后继续调度后续 pending 任务。
8. evalscope 和 OpenCompass 都按统一 watcher 字段判断完成：`status_file`、`summary_glob`、`done_file` 或 `completion_check_cmd` 任一达到完成即标记为 `通过`。
9. watcher 返回 `error/aborted`、服务启动失败、评测命令非零退出或超时时，标记为 `异常`，执行 `release_cmd`，然后继续调度后续 pending 任务。
10. 所有终态任务默认执行 `release_cmd`；默认释放动作是 `docker stop <container>`，释放 DCU 资源但保留容器。不得让完成任务持续占卡等待 Agent 回来。
11. 若 OpenCompass 任务因 `math_verify`、`latex2sympy2_extended`、`antlr4`、`human_eval` 等评测依赖缺失导致 eval 阶段失败，但已有 prediction/result，事件日志必须记录可恢复命令：`opencompass <config> -m eval -r <timestamp> -w <work_dir>`。
12. 若 OpenCompass 任务因推理阶段中断导致 prediction 缺失，事件日志必须记录可恢复命令：`opencompass <config> -m infer -r <timestamp> -w <work_dir>`。
13. 失败任务默认不阻塞后续队列；仅当用户计划显式声明 `stop_on_failure: true` 时才停止后续任务。
14. 所有任务进入终态后，保留最终版 `reports/task_plan.md` 和 `reports/test_report.md`；Agent 被用户唤醒后优先读取任务计划表并推送聊天总结。

### Step 6：计划表输出

向用户输出两张表。

资源表：

| 节点 | 加速卡型号 | 总卡数 | 空闲卡数 | 空闲卡 ID | 已占用端口 | 备注 |
|------|------------|--------|----------|-----------|------------|------|

任务计划表：

| 模型 | 测试工具 | 加速卡型号 | 状态 | 时间戳 |
|------|----------|------------|------|--------|

状态取值只能是：

- `待测试`：等待启动。
- `测试中`：服务启动、curl 检查或评测执行中。
- `通过`：任务完成。
- `异常`：服务、curl、评测或 watcher 异常。

节点、卡 ID、端口、容器名、模型路径、释放命令等详细字段写入 `plan.json`，不要塞进 Markdown 任务计划表。

计划表后必须询问用户确认或修改。用户确认前不得创建容器、启动服务或执行测试。

### Step 7：执行计划

用户确认后按波次执行：

1. 对每个 ready 任务创建或复用容器；创建时使用 `docker run -itd`，并按计划表将宿主模型路径只读挂载到 `/model/<模型名>`。
2. 生成或校验启动脚本；vLLM/SGLang 的模型路径必须统一为计划表中的容器模型路径。
3. 将启动脚本端口改为计划表端口。
4. 启动服务并用 `watch_llm_ready.sh` 监控 `/tmp/llm_status.json`。
5. 服务 `ready` 后必须先执行 curl 样本检查；响应正常且无乱码后才能执行对应精度/性能测试。
6. curl 检查失败或疑似乱码时，停止并释放该模型资源，在 `reports/test_report.md` 记录状态；若还有后续任务则继续调度。
7. 同波次模型服务并行启动和监控；模型内部的数据集队列独立推进，不设置“所有模型完成同一数据集后再进入下一个数据集”的全局屏障。
8. 某模型完成一个数据集后，立即启动该模型队列中的下一个数据集；某模型完成全部数据集后再释放该模型占用资源。
9. 执行过程中若端口被占用，可重新分配未使用端口，并同步更新计划表和启动脚本。
10. 若精度工具为 OpenCompass，启动评测前直接在容器内安装 `math_verify`、`latex2sympy2_extended`、`antlr4-python3-runtime`、`human-eval`，安装命令必须使用清华源；不要先逐个 import 检查这些常用依赖。eval 阶段失败但已有输出时，优先用 `-m eval -r <timestamp>` 补评估，infer 阶段中断时用 `-m infer -r <timestamp>` 续跑。
11. 若精度工具为 OpenCompass，使用 `references/opencompass_config_template.md` 生成配置；除非用户明确要求，数据集固定为 `gsm8k, math-500, openai_humaneval`，只替换模型/API/输出目录字段。

若计划进入后台 orchestrator 模式，Agent 在用户确认后必须：

1. 生成 `<run_dir>/plan.json`，包含所有 ready 任务及其 `start_cmd`、`service_status_file`、`eval_start_cmd`、`probe_url`、`served_model_path`、`release_cmd`、`status_file`、`output_dir` 字段。
2. 上传或引用 `scripts/auto_test_orchestrator.py`。
3. 用 `nohup python3 auto_test_orchestrator.py --plan <run_dir>/plan.json --run-dir <run_dir>` 启动后台编排器。
4. 向用户返回 `run_dir`、`state.json`、`events.log`、`orchestrator.log`、`reports/task_plan.md`、`reports/test_report.md` 路径。
5. 后续用户询问状态时优先读取 `reports/task_plan.md`，再读 `reports/test_report.md`、`state.json` 和 `events.log`，只有失败排查时才读取少量任务日志。

## 计划表确认提示

输出计划后使用以下提示：

```text
请确认这份测试计划是否可执行。您可以修改模型顺序、节点分配、卡数、端口、部署模式或删除 blocked 任务。确认后我将按波次执行。
```
