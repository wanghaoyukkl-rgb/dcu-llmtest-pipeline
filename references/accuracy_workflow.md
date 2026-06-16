# 精度测试执行、续跑与报告流程

本文件用于承接 `SKILL.md` 中的精度测试执行、OpenCompass 续跑、会话内 watch、结果提取和报告生成细节。旧监控和后台编排逻辑已移除；当前使用一次性 `scripts/watch_model_once.sh` 观察服务和 OpenCompass 进度。

## 前置判断

- 用户要求精度测试、继续评估或续跑时，如果需要生成/校验模型服务脚本、查询模型卡型/TP/PP/DP/部署参数，先按 `references/model_deployment_cookbook.md` 在 skill 根目录执行 `python3 scripts/update_cookbook_cache.py --check`。
- 用户明确要求更新 cookbook 时，执行 `python3 scripts/update_cookbook_cache.py --force` 后再继续精度测试流程。
- 当前版本不得生成临时监控脚本，不得启动旧后台编排逻辑，不得生成旧 JSON 状态文件；只能使用 skill 自带的一次性 watch 脚本。

## 测试参数

向用户确认以下信息，未提供时使用默认值：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 模型名 | 与推理服务一致 | 上一步所用模型 |
| 评测工具 | `evalscope` 或 `opencompass` | `opencompass`（用户明确要求快速验证/小样本时可用 `evalscope`） |
| 数据集 | 工具支持的数据集名或 OpenCompass 配置中的数据集 | evalscope: `gsm8k`；OpenCompass: `gsm8k, math-500, openai_humaneval` |
| limit | 测试条数，`0` 表示全量 | `10`（调试），正式测试去掉 |
| API 端口 | 推理服务端口 | 计划表或启动脚本端口 |
| 数据集宿主机路径 | 目标节点数据集根目录 | `/public/home/wanghy18/opencompass/data` |
| OpenCompass 配置 | 使用 OpenCompass 时需要 | 使用模板生成 |

默认解释：

- 用户说“模型测试”“精度测试”“所有模型测试完毕”且没有明确说只做服务探活时，按 OpenCompass 正式评测处理。
- `curl` 样本请求只用于确认服务可用和响应不乱码；`curl` 通过后必须启动评测工具，不能直接写完成标记或进入下一个模型。
- 只有用户明确要求“只做服务探活/只 curl 验证”时，才允许使用 `vllm-chat-probe` 或 `sglang-chat-probe`。

## 评测工具与数据集

启动前读取 `references/evaluation_framework/install_evaluation_framework.md`：

- 检查并安装 `evalscope` 或 `opencompass`。
- 除非用户明确指定使用本地现有 OpenCompass 工程，否则 OpenCompass 源码必须在容器内 `/workspace/opencompass` 拉取并安装；不要临时从宿主机查找或挂载已有工程。
- 如果用户明确指定本地现有 OpenCompass 工程路径，必须把该工程挂载到容器内 `/workspace/opencompass`，并在计划表或报告备注中记录 OpenCompass 来源为 `host-mounted:<path>`；默认容器内安装来源记录为 `container-installed`。
- 默认在模型服务容器内安装并运行评测工具；只有用户明确要求隔离评测容器，或服务容器不允许安装评测依赖时，才规划独立 eval 容器。独立 eval 容器必须提前记录到计划和报告中，不能作为服务 ready 后的隐式补救动作。
- OpenCompass 正式评测和续跑前，直接执行常用评测依赖安装：`math_verify`、`latex2sympy2_extended`、`antlr4-python3-runtime`、`human-eval`；不要先逐个 import 检查这些常用依赖。
- 数据集默认宿主机路径 `/public/home/wanghy18/opencompass/data`，容器内路径 `/mnt/opencompass/data`。
- `/mnt/opencompass/data` 只表示数据集路径，不作为 OpenCompass 工程路径。
- evalscope 的 gsm8k、humaneval、math_500 本地数据集特殊规则以该引用文件为准。

## 服务 ready 后 curl 样本检查

模型服务 ready 后、启动精度评测前，必须先执行一次 `/v1/chat/completions` 样本请求。响应是有效 JSON、能提取到非空文本且未疑似乱码时，才继续执行 evalscope/OpenCompass；请求失败、响应为空、非 JSON 或疑似乱码时，停止并释放当前任务资源，记录到 `reports/test_report.md`。

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

## evalscope 执行

当前版本不再提供 evalscope 后台监控脚本。若用户明确要求 evalscope 快速验证，使用 `scripts/eval_accuracy.sh` 启动评测，并把输出写入当前任务输出目录；默认正式精度测试仍使用 OpenCompass。

## OpenCompass 执行与续跑

OpenCompass 不使用 `eval_accuracy.sh`。常规进度 watch 只读取 OpenCompass 自动生成的 `logs/infer/`、`logs/eval/`，如果存在 `summary/` 则连带读取 summary。不要额外生成 `<model>.eval.log` 这类外层评测日志；不要把 `logs/launcher` 作为进度来源。

OpenCompass 启动必须满足：

- `eval_start_cmd` 在容器内后台启动 OpenCompass，不能只是创建完成标记。
- `eval_start_cmd` 必须调用 skill 自带的 `scripts/start_opencompass_safe.sh`；不要现场手写简化版启动脚本。
- `RUN_DIR` 是宿主机路径，只能用于宿主机侧创建 `reports/`、任务目录等；`CONFIG` 和 `work_dir` 是容器路径，必须位于 `/mnt/dcu-llmtest-run/...`，只能在 `docker exec` 内检查或创建。禁止在宿主机执行 `mkdir -p /mnt/dcu-llmtest-run/...`。
- OpenCompass 输出应以宿主机用户 UID/GID 在容器内启动，避免输出文件变成 root owner 后宿主机清理时报 `Permission denied`。
- 启动命令返回前必须完成三项检查：配置文件在容器内存在，`/workspace/opencompass/run.py` 或已安装 OpenCompass runner 可导入，后台 OpenCompass 进程启动后仍存活。
- `openai_api_base` 使用该模型计划端口，例如 `http://127.0.0.1:<port>/v1`。
- `work_dir` 固定为 `/mnt/dcu-llmtest-run/<TASK_ID>/opencompass`，宿主机对应路径为 `<RUN_DIR>/<TASK_ID>/opencompass`，便于按任务隔离结果。

固定启动模板：

```bash
ssh -tt <Node_IP> "bash <RUN_DIR>/scripts/start_opencompass_safe.sh \
  <TASK_ID> \
  <container_name> \
  /mnt/dcu-llmtest-run/opencompass_configs/<TASK_ID>.py \
  <RUN_DIR> \
  /mnt/dcu-llmtest-run/<TASK_ID>/opencompass \
  <Node_IP>"
```

OpenCompass 启动后，在当前会话内每 20 分钟执行一次：

```bash
ssh -tt <Node_IP> "bash <RUN_DIR>/scripts/watch_model_once.sh \
  accuracy <TASK_ID> <RUN_DIR> <container_name> <port> <vllm|sglang>"
```

该 watch 只读 `<RUN_DIR>/<TASK_ID>/opencompass/logs/infer`、`logs/eval` 最后 10 行；如果存在 `<RUN_DIR>/<TASK_ID>/opencompass/summary`，连带读取 summary。精度阶段还会轻量确认服务端口仍可访问，但不把服务日志作为 OpenCompass 进度来源。

若遇到类似本次 OpenCompass config/import/plugin 启动问题，允许改用容器内软链接兜底启动。兜底启动必须仍使用容器路径、记录 PID/log 和 work_dir，并继续按计划表维护状态：

```bash
mkdir -p /usr/local/lib/python3.10/dist-packages/autotest
ln -sfn /workspace/opencompass/opencompass/configs \
  /usr/local/lib/python3.10/dist-packages/autotest/configs
cd /mnt/dcu-llmtest-run/opencompass_configs
VLLM_PLUGINS="" python /workspace/opencompass/run.py xxx.py --debug
```

续跑/补评估规则：

- 用户要求“继续评估”“补评估”“复用已有输出”“评测依赖修好后继续算分”时，若已有 OpenCompass 输出时间戳，优先使用 `-m eval -r <timestamp>` 只重新执行评测汇总。
- 用户要求“继续推理”“补缺 prediction”“推理中断后续跑”时，使用 `-m infer -r <timestamp>` 续跑推理阶段。
- `<timestamp>` 为 OpenCompass 输出目录中的运行时间戳目录名，例如 `20260525_145907`；`<work_dir>` 为该时间戳目录的上一级输出目录。

```bash
opencompass <OpenCompass配置> -m eval -r <timestamp> -w <work_dir>
opencompass <OpenCompass配置> -m infer -r <timestamp> -w <work_dir>
```

若当前 OpenCompass 工程通过容器内源码启动，则等价命令为：

```bash
python /workspace/opencompass/run.py <OpenCompass配置> -m eval -r <timestamp> -w <work_dir>
python /workspace/opencompass/run.py <OpenCompass配置> -m infer -r <timestamp> -w <work_dir>
```

## OpenCompass 配置模板

生成 OpenCompass API 模型配置时必须读取 `references/opencompass_config_template.md`。除非用户明确要求：

- 数据集固定为 `gsm8k`、`math-500`、`openai_humaneval`。
- 固化 `temperature=0`、`query_per_second=64`、`max_out_len=16384`、`max_seq_len=32768`、`batch_size=32`、`extract_non_reasoning_content`。
- 每次只替换 `openai_api_base`、`tokenizer_path`、`path`、`abbr`、`work_dir`。

## 资源释放

默认释放策略：

- 单模型短任务：测试完成并提取结果后，停止服务或停止容器释放 DCU 资源；若这是本轮全部任务，随后删除本轮测试容器。
- 多模型/排队任务：某个模型完成全部数据集或进入失败终态后，立即 `docker stop <container_name>` 释放该模型资源，再扫描 `reports/task_plan.md` 中的 `待测试` 任务；只有加速卡型号匹配且空闲卡数满足 `所需卡数` 时，才分配卡和端口并启动后续任务。
- 所有任务均进入 `通过` 或 `异常` 后，对本轮 skill 管理的测试容器执行 `docker stop <container_name>` 后再 `docker rm <container_name>`。用户明确要求“评测结束后保持服务可用”时，需说明会继续占用卡且不执行删除。

## 结果提取

若使用 OpenCompass，优先从输出目录中的 `summary/`、`logs/eval/` 和 `logs/infer/` 提取，不要只依赖 `/tmp` 外层日志。

若 summary 中某数据集为 `-`：

1. 先看 `logs/eval/<模型>/<dataset>.out` 尾部。
2. 若是依赖缺失且已有 OpenCompass 输出时间戳，补依赖后只跑 `-m eval -r <timestamp> -w <work_dir>`。
3. `math-500` 常见缺失为 `antlr4`，安装包名为 `antlr4-python3-runtime`。

提取字段：

- 各数据集精度数值：accuracy、pass@k 等。
- 测试耗时。
- 评测样本数量。
- 警告、跳过、失败或中断信息。

## 报告生成

默认生成两个 Markdown 文件。

`reports/task_plan.md` 为人工计划表，内容保持固定表头：

| 模型 | 测试工具 | 加速卡型号 | 加速卡信息 | 所需卡数 | 状态 | 时间戳 |
|------|----------|------------|------------|----------|------|--------|

状态只允许 `待测试`、`测试中`、`通过`、`异常`。初始化写入所有计划任务；动态调度时允许更新 `加速卡信息`、`所需卡数`、状态栏和时间戳，普通进度更新只改状态栏和时间戳。

`reports/test_report.md` 为唯一测试报告，内容保持简洁，只包含一张结果表：

| 任务ID | 模型 | 数据集 | 节点 | 状态 | 结果/进度 | 输出 |
|--------|------|--------|------|------|-----------|------|

不得生成重复摘要报告。正式报告或复盘文档才读取 `references/accuracy_report_template.md` 扩展环境、异常和后续建议。
