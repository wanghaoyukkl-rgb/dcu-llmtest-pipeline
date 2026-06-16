# 精度评测框架安装与选择

精度测试前，先让用户选择评测工具：

1. `evalscope`：默认推荐，适合 vLLM/SGLang API 快速评测。
2. `opencompass`：适合需要 OpenCompass 数据集、配置和报告体系的正式评测。

如果用户没有指定，默认使用 `evalscope`。如果用户要求和既有 OpenCompass 数据集/配置保持一致，则选择 `opencompass`。

## pip 源规则

所有 `pip install` 默认使用清华源，不要先使用默认源试错：

```bash
pip install <packages> -i https://pypi.tuna.tsinghua.edu.cn/simple
```

如需多条安装命令，可先设置：

```bash
export PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
```

除非包解析明确失败，不要默认加 `--no-deps`；OpenCompass 的数学评测依赖存在传递依赖，跳过依赖安装容易漏掉 `antlr4-python3-runtime`。

## 容器内环境检查

创建容器后、启动精度测试前，必须先确认容器中是否已有对应评测环境。

通用检查用于确认评测工具本体是否可用；OpenCompass 的常用评测依赖不要逐个检查，按下一节直接安装。

```bash
docker exec <container_name> bash -lc "python - <<'PY'
import importlib.util
for name in ['evalscope', 'opencompass', 'openai']:
    print(f'{name}:', 'OK' if importlib.util.find_spec(name) else 'MISSING')
PY"
```

按工具检查：

```bash
docker exec <container_name> bash -lc "pip list | grep evalscope"
docker exec <container_name> bash -lc "python - <<'PY'
import importlib.util
for name in ['opencompass', 'openai']:
    print(f'{name}:', 'OK' if importlib.util.find_spec(name) else 'MISSING')
PY"
```

若目标工具未安装，先按下面安装方式安装并验证；不要直接启动精度测试。

## evalscope 安装

源码安装必须在容器内 `/workspace` 执行：

```bash
mkdir -p /workspace
cd /workspace
git clone https://github.com/modelscope/evalscope.git
cd /workspace/evalscope
pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple
```

可选安装完整依赖。执行前询问用户是否安装完整依赖；用户确认后再执行：

```bash
pip install '.[all]' -i https://pypi.tuna.tsinghua.edu.cn/simple
```

安装后验证：

```bash
pip list | grep evalscope
evalscope --help
```

## OpenCompass 安装

默认源码安装必须在容器内 `/workspace` 执行。除非用户明确指定使用本地现有 OpenCompass 工程，否则不要挂载宿主机 OpenCompass 工程，也不要在节点宿主机上查找已有代码：

```bash
mkdir -p /workspace
cd /workspace
git clone https://github.com/open-compass/opencompass.git
cd /workspace/opencompass
pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple
```

如果用户明确指定使用本地现有 OpenCompass 工程，则必须在创建容器时将该工程挂载到容器内 `/workspace/opencompass`，并在计划表或报告备注中记录来源为 `host-mounted:<path>`。默认源码安装来源记录为 `container-installed`。

安装常用依赖：

```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

若需要 API 模型评测，额外确认 `openai` Python 包是否可用：

```bash
pip install openai -i https://pypi.tuna.tsinghua.edu.cn/simple
```

正式评测常用数据集依赖必须直接安装，不要先逐个 import 检查：

- `math_verify`：math-500 等数学评测常用。
- `latex2sympy2_extended`：数学表达式解析常用。
- `antlr4-python3-runtime`：`latex2sympy2_extended` 的运行依赖，Python 导入名为 `antlr4`；缺失时 math-500 eval 会失败但 prediction 可能已完成。
- `human_eval`：HumanEval 评测模块，对应 pip 包名为 `human-eval`。

固定安装命令：

```bash
pip install math_verify latex2sympy2_extended antlr4-python3-runtime human-eval -i https://pypi.tuna.tsinghua.edu.cn/simple
```

安装后只需确认 OpenCompass runner 可用；除非安装失败或 eval 报错，不再默认做全量 import 检查。OpenCompass 启动必须交给 `scripts/start_opencompass_safe.sh` 完成该检查，该脚本会在容器内确认 `/workspace/opencompass/run.py` 或已安装 `opencompass` 可用，并避免宿主机/容器路径混用：

```bash
bash <RUN_DIR>/scripts/start_opencompass_safe.sh \
  <TASK_ID> <CONTAINER> \
  /mnt/dcu-llmtest-run/opencompass_configs/<TASK_ID>.py \
  <RUN_DIR> \
  /mnt/dcu-llmtest-run/<TASK_ID>/opencompass \
  <NODE_IP>
```

若遇到类似本次 OpenCompass config/import/plugin 启动问题，允许在容器内建立 OpenCompass configs 软链接并用 run.py 兜底启动：

```bash
mkdir -p /usr/local/lib/python3.10/dist-packages/autotest
ln -sfn /workspace/opencompass/opencompass/configs \
  /usr/local/lib/python3.10/dist-packages/autotest/configs
cd /mnt/dcu-llmtest-run/opencompass_configs
VLLM_PLUGINS="" python /workspace/opencompass/run.py xxx.py --debug
```

## OpenCompass 续跑与补评估

当 OpenCompass 推理已产生 prediction/result，但评测阶段因为依赖缺失、评测脚本错误或汇总中断失败时，修复环境后优先只重跑 eval 阶段：

```bash
opencompass <OpenCompass配置> -m eval -r <timestamp> -w <work_dir>
```

当 OpenCompass 推理阶段中断或需要补齐缺失 prediction 时，使用 infer 续跑：

```bash
opencompass <OpenCompass配置> -m infer -r <timestamp> -w <work_dir>
```

说明：

- `<timestamp>` 是 OpenCompass 输出目录中的运行时间戳目录名，例如 `20260525_145907`。
- `<work_dir>` 是时间戳目录的上一级输出目录。
- 补评估前先执行上面的固定安装命令；否则容易出现只有部分数据集生成 summary 的情况。
- 若 summary 中 `math-500` 为 `-` 且 `logs/eval/<模型>/math-500.out` 出现 `ModuleNotFoundError: No module named 'antlr4'`，先安装 `antlr4-python3-runtime`，再用 `-m eval -r <timestamp> -w <work_dir>` 补算分，不要重跑 infer。

## 工具选择规则

- 用户说“快速精度测试”“先跑少量样本”“服务 API 方式”时，优先 `evalscope`。
- 用户说“OpenCompass”“正式报告”“复用 opencompass 数据集/配置”时，选择 `opencompass`。
- 如果两者都未安装，先询问用户选择哪个工具，再安装对应工具。
- 如果用户不确定，建议先用 `evalscope` 跑小样本，再根据需要切换到 `opencompass` 做正式评测。

## 数据集准备

- 默认宿主机数据集根目录：`/public/home/wanghy18/opencompass/data`。
- 默认容器内数据集根目录：`/mnt/opencompass/data`。
- 创建精度测试容器时，必须将数据集目录只读挂载：`-v <HOST_DATASET_PATH>:/mnt/opencompass/data:ro`。
- 如果默认宿主机数据集目录不存在，不要自动下载大数据集；先向用户确认数据集来源、路径和是否允许下载。
- `evalscope` 默认数据集路径约定：`/mnt/opencompass/data/<数据集名>`。
- `/mnt/opencompass/data` 只表示数据集路径；OpenCompass 工程默认在 `/workspace/opencompass`，不得默认使用 `/mnt/opencompass` 承载工程代码。

## evalscope 本地数据集特殊规则

### gsm8k

现象：

```text
BuilderConfig 'main' not found. Available: ['default']
```

处理：

```json
{"gsm8k": {"local_path": "/mnt/opencompass/data/gsm8k", "subset_list": ["default"]}}
```

### humaneval

现象：

```text
BuilderConfig 'openai_humaneval' not found. Available: ['default']
```

处理：

```json
{"humaneval": {"local_path": "/mnt/opencompass/data/humaneval", "subset_list": ["default"]}}
```

如果用户或旧配置写的是 `openai_humaneval`，本地评测时应规范化为 `humaneval`。

### math_500

实测本地目录为：

```text
/public/home/wanghy18/opencompass/data/math/test.jsonl
```

容器内对应路径为：

```text
/mnt/opencompass/data/math/test.jsonl
```

处理：

```json
{"math_500": {"local_path": "/mnt/opencompass/data/math", "subset_list": ["default"]}}
```

注意：

- 不要直接用 `head -n 10` 截断原始 `test.jsonl` 作为小样本文件。
- 小样本测试优先使用评测工具的 `limit` 参数。
- 若出现 `KeyError: 'answer'`，先检查 JSONL 是否保留 `answer` 字段；字段缺失时要求用户提供修正后的数据文件或确认转换规则。

## 运行结果判断

- 旧运行监控脚本已移除；当前使用 `scripts/watch_model_once.sh` 做会话内 one-shot 观察。
- evalscope 输出应写入当前任务输出目录。
- OpenCompass 常规进度只读取 `logs/infer/`、`logs/eval/`，如果存在 `summary/` 则连带读取 summary；固定启动脚本产生的启动日志只用于启动阶段排障，不作为完成判断来源。
- 服务阶段每 2 分钟调用一次 `watch_model_once.sh serve ...`；精度阶段每 20 分钟调用一次 `watch_model_once.sh accuracy ...`。
- prediction 文件不再用于早期乱码检查；乱码检查改为模型服务 `ready` 后、评测启动前的 curl 样本请求。
- 多模型多数据集测试时，每个模型维护独立数据集队列；某模型完成一个数据集后可立即进入下一个数据集，不等待其他模型完成同一数据集。
