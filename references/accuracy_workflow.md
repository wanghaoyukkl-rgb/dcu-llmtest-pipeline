# 精度测试执行、续跑与报告流程

本文件用于承接 `SKILL.md` 中的精度测试执行、待机监控、后台 orchestrator、结果提取和报告生成细节。用户要求精度测试、继续评估、OpenCompass 续跑、查看进度或生成报告时读取。

## 目录

- 前置判断
- 测试参数
- 评测工具与数据集
- 服务 ready 后 curl 样本检查
- evalscope 执行
- OpenCompass 执行与续跑
- OpenCompass 配置模板
- watcher 监控
- 短任务待机与自动报告
- 长队列 orchestrator
- 资源释放
- 结果提取
- 报告生成

## 前置判断

精度测试可能持续数小时乃至 24 小时以上，不能依赖 Agent 会话保持连接来轮询。

- 用户要求精度测试、继续评估、续跑，或 Agent 被唤醒后要继续推进精度任务时，如果需要生成/校验模型服务脚本、查询模型卡型/TP/PP/DP/部署参数，先按 `references/model_deployment_cookbook.md` 在 skill 根目录执行 `python3 scripts/update_cookbook_cache.py --check`。超过 3 天才更新 cookbook；未超过 3 天只记录本次检查。
- 用户明确要求更新 cookbook 时，执行 `python3 scripts/update_cookbook_cache.py --force` 后再继续精度测试流程。
- 单模型/短任务：可在节点宿主机上启动 `watch_accuracy.sh`，由它独立运行并写状态文件。
- OpenCompass 长任务、多模型、多波次或后续有排队任务：必须启动 `scripts/auto_test_orchestrator.py`，由它读取 OpenCompass 输出目录或 watcher 状态，记录错误，终态后释放资源并启动后续排队任务。
- Agent 会话只负责启动、低频读取状态和向用户汇报；长队列后续推进必须由 orchestrator 完成。
- 不要再生成临时 `monitor_status.py` 这类只写 `status.json`、但没有事件日志和释放动作的监控脚本。

## 测试参数

向用户确认以下信息，未提供时使用默认值：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 模型名 | 与推理服务一致 | 上一步所用模型 |
| 评测工具 | `evalscope` 或 `opencompass` | `evalscope` |
| 数据集 | 工具支持的数据集名或 OpenCompass 配置中的数据集 | evalscope: `gsm8k`；OpenCompass: `gsm8k, math-500, openai_humaneval` |
| limit | 测试条数，`0` 表示全量 | `10`（调试），正式测试去掉 |
| API 端口 | 推理服务端口 | 计划表或启动脚本端口 |
| 数据集宿主机路径 | 目标节点数据集根目录 | `/public/home/wanghy18/opencompass/data` |
| OpenCompass 配置 | 使用 OpenCompass 时需要 | 用户提供或现场确认 |

多模型多数据集时，每个模型维护自己的数据集队列，例如 `gsm8k -> math_500 -> humaneval`；某个模型完成当前数据集后立即进入下一个数据集，不等待其他模型。

## 评测工具与数据集

启动前读取 `references/evaluation_framework/install_evaluation_framework.md`：

- 检查并安装 `evalscope` 或 `opencompass`。
- OpenCompass 正式评测和续跑前，直接执行常用评测依赖安装：`math_verify`、`latex2sympy2_extended`、`antlr4-python3-runtime`、`human-eval`；不要先逐个 import 检查这些常用依赖。
- 数据集默认宿主机路径 `/public/home/wanghy18/opencompass/data`，容器内路径 `/mnt/opencompass/data`。
- evalscope 的 gsm8k、humaneval、math_500 本地数据集特殊规则以该引用文件为准。

## 服务 ready 后 curl 样本检查

模型服务 watcher 状态为 `ready` 后、启动精度评测前，必须先执行一次 `/v1/chat/completions` 样本请求。响应是有效 JSON、能提取到非空文本且未疑似乱码时，才继续执行 evalscope/OpenCompass；请求失败、响应为空、非 JSON 或疑似乱码时，停止并释放当前任务资源，记录到 `reports/test_report.md`，若还有 pending 任务则继续下一个。

默认 curl 模板：

```bash
curl http://<地址>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "/model/<模型名>",
    "messages": [
      {"role": "user", "content": "介绍一下人工智能发展史"}
    ],
    "max_tokens": 500,
    "temperature": 0.0
  }'
```

后台 orchestrator 计划中推荐拆分服务启动和评测启动：`start_cmd` 只负责启动模型服务，`service_status_file` 指向 `/tmp/llm_status.json`，`eval_start_cmd` 负责启动精度评测。orchestrator 会在 `service_status_file` 为 `ready` 后自动执行上述 curl 检查，通过后再运行 `eval_start_cmd`。

## evalscope 执行

上传脚本：

```bash
scp scripts/eval_accuracy.sh <Node_IP>:/tmp/eval_accuracy.sh
scp scripts/watch_accuracy.sh <Node_IP>:/tmp/watch_accuracy.sh
```

在容器内后台启动：

```bash
ssh -tt <Node_IP> "docker exec -d <container_name> bash -c \
  'bash /tmp/eval_accuracy.sh <模型名> <数据集> <limit> \
   <端口> \
   > /tmp/eval_accuracy.log 2>&1'"
```

## OpenCompass 执行与续跑

OpenCompass 不使用 `eval_accuracy.sh`。优先使用 OpenCompass 自己的输出目录作为进度与结果来源：`predictions/`、`results/`、`logs/infer/`、`logs/eval/`、`summary/`。不要额外生成 `<model>.eval.log`；后台任务只保留 `orchestrator.log/events.log/state.json`。

启动前必须直接安装常用评测依赖。`pip install` 对已安装包是幂等的，不要先逐个 import 检查这些依赖：

```bash
docker exec <container_name> bash -lc \
  "pip install math_verify latex2sympy2_extended antlr4-python3-runtime human-eval \
   -i https://pypi.tuna.tsinghua.edu.cn/simple"
```

普通启动模板：

```bash
ssh -tt <Node_IP> "docker exec -d <container_name> bash -lc \
  'unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; \
   export no_proxy=<Node_IP>,localhost,127.0.0.1; \
   export NO_PROXY=<Node_IP>,localhost,127.0.0.1; \
   export COMPASS_DATA_CACHE=/mnt/opencompass; \
   export PYTHONPATH=/mnt/opencompass:\${PYTHONPATH:-}; \
   cd /mnt/acc/<run_dir> && \
   if [ -f /mnt/opencompass/run.py ]; then \
     python /mnt/opencompass/run.py <OpenCompass配置>; \
   else \
     opencompass <OpenCompass配置>; \
   fi'"
```

说明：

- `COMPASS_DATA_CACHE=/mnt/opencompass` 用于优先复用挂载的数据集目录 `/mnt/opencompass/data`，避免 OpenCompass 自动下载到 `/root/.cache/opencompass`。
- 后台运行由 orchestrator 管理，不要在每个模型旁边生成 `qwen*.eval.log` 这类外层日志；需要排查时读取 OpenCompass 输出目录中的日志。
- 若需要手工后台启动，最多将 launcher 输出重定向到 `<run_dir>/opencompass_launcher.log`，不要把它作为进度来源。

续跑/补评估规则：

- 用户要求“继续评估”“补评估”“复用已有结果”“评测依赖修好后继续算分”时，若已有 prediction/result 输出，优先使用 `-m eval -r <timestamp>` 只重新执行评测汇总。
- 用户要求“继续推理”“补缺 prediction”“推理中断后续跑”时，使用 `-m infer -r <timestamp>` 续跑推理阶段。
- `<timestamp>` 为 OpenCompass 输出目录中的运行时间戳目录名，例如 `20260525_145907`；`<work_dir>` 为该时间戳目录的上一级输出目录。

```bash
opencompass <OpenCompass配置> -m eval -r <timestamp> -w <work_dir>
opencompass <OpenCompass配置> -m infer -r <timestamp> -w <work_dir>
```

若当前 OpenCompass 工程只能通过 `/mnt/opencompass/run.py` 启动，则等价命令为：

```bash
python /mnt/opencompass/run.py <OpenCompass配置> -m eval -r <timestamp> -w <work_dir>
python /mnt/opencompass/run.py <OpenCompass配置> -m infer -r <timestamp> -w <work_dir>
```

## OpenCompass 配置模板

生成 OpenCompass API 模型配置时必须读取 `references/opencompass_config_template.md`。除非用户明确要求：

- 数据集固定为 `gsm8k`、`math-500`、`openai_humaneval`。
- 固化 `temperature=0`、`query_per_second=64`、`max_out_len=16384`、`max_seq_len=32768`、`batch_size=32`、`extract_non_reasoning_content`。
- 每次只替换 `openai_api_base`、`tokenizer_path`、`path`、`abbr`、`work_dir`。

## watcher 监控

evalscope 快速验证和 OpenCompass 正式验证统一使用 `scripts/watch_accuracy.sh` 或 orchestrator 内置的同一套 watch 字段，不再拆分两套监控规则。watcher 运行在宿主机，通过 `nohup` 挂后台，写状态文件、`reports/test_report.md` 和 `reports/task_plan.md`。

统一完成判断来源：

- `status_file`：watcher 写出的 JSON 状态。
- `SUMMARY_GLOB` / `summary_glob`：OpenCompass summary 文件匹配。
- `DONE_FILE` / `done_file`：非空完成标记文件。
- `COMPLETION_CHECK_CMD` / `completion_check_cmd`：自定义完成检查命令。
- `log_file`：evalscope 或自定义评测日志，用于错误和结果兜底判断。

watch 间隔：

- 短任务默认 10 分钟一次：`600` 秒。
- 长时间任务默认 30 分钟一次：`1800` 秒。
- 用户手动查询时，优先读 `reports/task_plan.md`，再读 `state.json/events.log`。

失败排查才读取 `logs/eval/<模型>/<dataset>.out`、`logs/infer/<模型>/<dataset>.out` 或评测日志尾部。不要创建只写空 `monitor_status.log` 的自定义监控体系。

```bash
ssh -tt <Node_IP> "REPORT_FILE=<run_dir>/reports/test_report.md \
  PLAN_FILE=<run_dir>/reports/task_plan.md \
  TASK_ID=<任务ID> \
  REPORT_MODEL=<模型名> \
  REPORT_DATASET=<数据集> \
  REPORT_NODE=<Node_IP> \
  REPORT_OUTPUT_DIR=<输出目录> \
  TEST_TOOL=<evalscope|opencompass> \
  ACCELERATOR=<加速卡型号> \
  SUMMARY_GLOB='<OpenCompass summary glob 可选>' \
  nohup bash /tmp/watch_accuracy.sh \
  /tmp/eval_accuracy.log \
  /tmp/eval_status.json \
  <container_name> \
  600 \
  > /tmp/watch_accuracy.monitor.log 2>&1 & echo 监控进程PID: $!"
```

记录任务清单时至少保存：模型、评测工具、节点、容器、端口、状态文件、日志路径、输出目录、当前状态。

## 短任务待机与自动报告

短任务可以在当前会话内低频待机：

- 默认每 10 分钟读取一次 watcher/orchestrator 状态；长时间任务按 30 分钟一次，或仅在用户手动查询时读取。
- 每轮只读取小型 JSON 状态文件和必要的 `events.log` 尾部，不固定读取完整日志。
- 仅当状态变化、出现 `error/aborted`、或所有计划项完成时更新用户。

状态处理：

| status | 含义 | 操作 |
|--------|------|------|
| `running` | 仍在测试 | 展示 `progress`，继续等待 |
| `done` | 完成 | 收集完整结果 |
| `error` | 出错 | watcher/orchestrator 已尝试释放资源；展示报错和日志路径 |
| `aborted` | curl 样本检查疑似乱码或主动中断 | 资源已释放，容器保留；反馈用户 |

所有计划项完成后，自动收集结果并推送报告，不等用户再次询问。

## 长队列 orchestrator

多模型、多波次、或预计跨小时/跨天的计划必须落盘并由后台 orchestrator 执行。详细计划规则见 `references/auto_test_plan.md`。

落盘结构建议：

```text
<run_dir>/
  plan.json
  state.json
  events.log
  reports/
  task_<ID>/
```

启动模板：

```bash
nohup python3 auto_test_orchestrator.py --plan <run_dir>/plan.json --run-dir <run_dir> \
  > <run_dir>/orchestrator.log 2>&1 &
```

orchestrator 必须：

- 维护 `state.json` 和 `events.log`。
- 持续生成并更新 `reports/test_report.md`，以简洁表格记录任务状态和测试结果。
- 持续生成并更新 `reports/task_plan.md`，表头固定为 `模型、测试工具、加速卡型号、状态、时间戳`，状态只使用 `待测试/测试中/通过/异常`。
- 事件必须同时追加到 `events.log`，并输出到 `orchestrator.log`，避免后台日志为空。
- 出现服务启动失败、curl 样本请求失败/乱码、评测错误、watcher `error/aborted` 或超时时执行 `release_cmd`。
- 任务 `done/failed/aborted` 后默认执行 `release_cmd` 停止容器，释放 DCU 显存；容器以 stopped 状态保留，除非用户明确要求删除或保持运行。
- 失败任务默认不阻塞后续 pending 任务。
- 所有任务终态后保留最终版 `reports/task_plan.md` 和 `reports/test_report.md`，并兼容写入 `reports/summary.md`。

## 资源释放

默认释放策略：

- 单模型短任务：测试完成并提取 summary 后，停止服务或停止容器释放 DCU 资源。
- 多模型/排队任务：某个模型完成全部数据集或进入失败终态后，orchestrator 必须立即释放该模型资源，再调度后续 pending 任务。
- 默认释放命令为 `docker stop <container_name>`；这会释放 DCU 显存并保留容器。只有用户明确要求清理时才执行 `docker rm`。
- 用户明确要求“评测结束后保持服务可用”时，计划中设置 `release_on_done=false` 并说明会继续占用卡。

## 结果提取

测试完成后读取完整结果日志或 summary：

```bash
ssh -tt <Node_IP> "docker exec <container_name> cat /tmp/eval_accuracy.log"
```

若使用 OpenCompass，优先从输出目录中的 `summary/`、`results/`、`logs/eval/` 和 `logs/infer/` 提取，不要只依赖 `/tmp` 外层日志。

若 summary 中某数据集为 `-`：

1. 先看 `logs/eval/<模型>/<dataset>.out` 尾部。
2. 若是依赖缺失且已有 prediction/result，补依赖后只跑 `-m eval -r <timestamp> -w <work_dir>`。
3. `math-500` 常见缺失为 `antlr4`，安装包名为 `antlr4-python3-runtime`。

提取字段：

- 各数据集精度数值：accuracy、pass@k 等。
- 测试耗时。
- 评测样本数量。
- 警告、跳过、失败或中断信息。

## 报告生成

默认生成两个 Markdown 文件。

`reports/task_plan.md` 为任务计划表，内容保持固定表头：

| 模型 | 测试工具 | 加速卡型号 | 状态 | 时间戳 |
|------|----------|------------|------|--------|

状态只允许 `待测试`、`测试中`、`通过`、`异常`。初始化写入所有计划任务，后续任务启动、异常、完成等节点只更新状态栏和时间戳。

`reports/test_report.md` 为测试报告，内容保持简洁，只包含一张结果表：

| 任务ID | 模型 | 数据集 | 节点 | 状态 | 结果/进度 | 输出 |
|--------|------|--------|------|------|-----------|------|

正式报告或复盘文档才读取 `references/accuracy_report_template.md` 扩展环境、异常和后续建议。
