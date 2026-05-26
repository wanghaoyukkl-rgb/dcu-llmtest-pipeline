# 精度测试执行、续跑与报告流程

本文件用于承接 `SKILL.md` 中的精度测试执行、待机监控、后台 orchestrator、结果提取和报告生成细节。用户要求精度测试、继续评估、OpenCompass 续跑、查看进度或生成报告时读取。

## 目录

- 前置判断
- 测试参数
- 评测工具与数据集
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
- OpenCompass 正式评测前确认 `opencompass`、`openai`、`math_verify`、`latex2sympy2_extended`、`antlr4`、`human_eval`。
- 数据集默认宿主机路径 `/public/home/wanghy18/opencompass/data`，容器内路径 `/mnt/opencompass/data`。
- evalscope 的 gsm8k、humaneval、math_500 本地数据集特殊规则以该引用文件为准。

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

启动前必须检查依赖；缺失时先补装：

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

监控脚本运行在宿主机，通过 `nohup` 挂后台，读取评测日志并写状态文件。不要固定时间读取模型服务日志；evalscope 测试进度优先从 `/tmp/eval_accuracy.log`、状态 JSON 和 prediction 文件判断。

OpenCompass 进度判断规则：

- 优先读 orchestrator 的 `state.json` 和 `events.log`。
- 其次按 OpenCompass 输出目录判断：`predictions/<模型>/*.json` 条数、`results/<模型>/*.json`、`summary/*.csv`。
- 失败排查才读取 `logs/eval/<模型>/<dataset>.out` 或 `logs/infer/<模型>/<dataset>.out` 的尾部。
- 不要创建只写空 `monitor_status.log` 的自定义监控体系；需要后台状态时必须由 orchestrator 写事件和状态。

每个模型只做一次 prediction 早期检查：默认评测启动 600 秒后，读取前 3 条有文本样本；若 3 条均疑似乱码，则按错误处理并释放该模型资源。

```bash
ssh -tt <Node_IP> "nohup bash /tmp/watch_accuracy.sh \
  /tmp/eval_accuracy.log \
  /tmp/eval_status.json \
  auto \
  <container_name> \
  120 \
  600 \
  > /tmp/watch_accuracy.monitor.log 2>&1 & echo 监控进程PID: $!"
```

记录任务清单时至少保存：模型、评测工具、节点、容器、端口、状态文件、日志路径、输出目录、当前状态。

## 短任务待机与自动报告

短任务可以在当前会话内低频待机：

- 默认每 10 分钟读取一次 watcher/orchestrator 状态；用户要求更久时可放宽到 15-30 分钟。
- 每轮只读取小型 JSON 状态文件和必要的 `events.log` 尾部，不固定读取完整日志。
- 仅当状态变化、出现 `error/aborted`、或所有计划项完成时更新用户。

状态处理：

| status | 含义 | 操作 |
|--------|------|------|
| `running` | 仍在测试 | 展示 `progress`，继续等待 |
| `done` | 完成 | 收集完整结果 |
| `error` | 出错 | watcher/orchestrator 已尝试释放资源；展示报错和日志路径 |
| `aborted` | prediction 前 3 条疑似乱码 | 资源已释放，容器保留；反馈用户 |

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
- 事件必须同时追加到 `events.log`，并输出到 `orchestrator.log`，避免后台日志为空。
- 出现服务启动失败、评测错误、watcher `error/aborted`、prediction 乱码或超时时执行 `release_cmd`。
- 任务 `done/failed/aborted` 后默认执行 `release_cmd` 停止容器，释放 DCU 显存；容器以 stopped 状态保留，除非用户明确要求删除或保持运行。
- 失败任务默认不阻塞后续 pending 任务。
- 所有任务终态后在 `reports/` 写最终汇总草稿。

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

报告默认包含：

- 测试环境：节点、卡型、镜像、框架、容器、模型路径、服务端口。
- 计划总览：模型、数据集队列、状态、开始/结束时间、输出目录。
- 指标表：按 `<模型, 数据集>` 汇总 accuracy、pass@k 等主要指标。
- 异常与备注：启动警告、评测跳过、失败任务、乱码检测、依赖安装调整。
- 后续建议：是否保留服务/容器、是否清理环境、是否补跑失败数据集。

若用户需要正式报告格式，或自动报告需要沉淀为文档，读取 `references/accuracy_report_template.md`。
