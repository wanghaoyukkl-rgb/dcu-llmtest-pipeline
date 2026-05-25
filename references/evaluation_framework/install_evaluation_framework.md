# 精度评测框架安装与选择

精度测试前，先让用户选择评测工具：

1. `evalscope`：默认推荐，适合 vLLM/SGLang API 快速评测。
2. `opencompass`：适合需要 OpenCompass 数据集、配置和报告体系的正式评测。

如果用户没有指定，默认使用 `evalscope`。如果用户要求和既有 OpenCompass 数据集/配置保持一致，则选择 `opencompass`。

## 容器内环境检查

创建容器后、启动精度测试前，必须先确认容器中是否已有对应评测环境。

通用检查：

```bash
docker exec <container_name> bash -lc "python - <<'PY'
import importlib.util
for name in ['evalscope', 'opencompass', 'openai', 'math_verify', 'latex2sympy2_extended', 'human_eval']:
    print(f'{name}:', 'OK' if importlib.util.find_spec(name) else 'MISSING')
PY"
```

按工具检查：

```bash
docker exec <container_name> bash -lc "pip list | grep evalscope"
docker exec <container_name> bash -lc "python - <<'PY'
import importlib.util
for name in ['opencompass', 'openai', 'math_verify', 'latex2sympy2_extended', 'human_eval']:
    print(f'{name}:', 'OK' if importlib.util.find_spec(name) else 'MISSING')
PY"
```

若目标工具未安装，先按下面安装方式安装并验证；不要直接启动精度测试。

## evalscope 安装

源码安装：

```bash
git clone https://github.com/modelscope/evalscope.git
cd evalscope
pip install -e .
```

可选安装完整依赖。执行前询问用户是否安装完整依赖；用户确认后再执行：

```bash
pip install '.[all]'
```

安装后验证：

```bash
pip list | grep evalscope
evalscope --help
```

## OpenCompass 安装

源码安装：

```bash
git clone https://github.com/open-compass/opencompass.git
cd opencompass
pip install -e .
```

安装常用依赖：

```bash
pip install -r requirements.txt
```

若需要 API 模型评测，额外确认 `openai` Python 包是否可用：

```bash
pip install openai
```

正式评测常用数据集依赖必须同时确认：

- `math_verify`：math-500 等数学评测常用。
- `latex2sympy2_extended`：数学表达式解析常用。
- `human_eval`：HumanEval 评测模块，对应 pip 包名为 `human-eval`。

补装命令：

```bash
pip install math_verify latex2sympy2_extended human-eval
```

安装后验证：

```bash
python - <<'PY'
import importlib.util
for name in ['opencompass', 'openai', 'math_verify', 'latex2sympy2_extended', 'human_eval']:
    print(f'{name}:', 'OK' if importlib.util.find_spec(name) else 'MISSING')
PY
python -m opencompass --help
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
- 补评估前先确认依赖检查全部为 `OK`；否则容易出现只有部分数据集生成 summary 的情况。

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
- `opencompass` 默认优先使用 OpenCompass 工程内配置和数据集路径。

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

## evalscope 运行监控

- evalscope 会生成评测日志和 prediction 相关文件；进度判断优先读取评测日志和 watcher 状态文件，不要固定时间读取模型服务日志。
- 启动测试后，使用 `scripts/watch_accuracy.sh` 监控 `/tmp/eval_accuracy.log` 和 prediction 文件。
- 如果 prediction 刚生成后连续 3 条样本疑似乱码，watcher 应中断当前模型评测/服务进程以释放加速卡资源，同时保留容器并向用户反馈。
- 多模型多数据集测试时，每个模型维护独立数据集队列；某模型完成一个数据集后可立即进入下一个数据集，不等待其他模型完成同一数据集。
