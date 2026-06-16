# OpenCompass API 配置模板

用于 SGLang/vLLM OpenAI API 形式的正式精度评测。除非用户明确要求改数据集或参数，生成配置时只替换以下 5 个字段：

- `work_dir`
- `abbr`
- `path`
- `tokenizer_path`
- `openai_api_base`

默认数据集固定为：

- `gsm8k`
- `math-500`
- `openai_humaneval`

默认推理参数固定为：

- `temperature=0`
- `query_per_second=64`
- `max_out_len=16384`
- `max_seq_len=32768`
- `batch_size=32`
- `pred_postprocessor=extract_non_reasoning_content`

## 配置模板

```python
from mmengine.config import read_base

with read_base():
    from opencompass.configs.datasets.gsm8k.gsm8k_gen_17d0dc import gsm8k_datasets
    from opencompass.configs.datasets.math.math_500_gen import math_datasets
    from opencompass.configs.datasets.humaneval.humaneval_gen import humaneval_datasets
    from opencompass.configs.summarizers.example import summarizer

datasets = sum(
    [v for k, v in locals().items() if k.endswith("_datasets") or k == "datasets"],
    [],
)

work_dir = "<WORK_DIR>"

from opencompass.models import OpenAISDK

api_meta_template = dict(round=[
    dict(role="HUMAN", api_role="HUMAN"),
    dict(role="BOT", api_role="BOT", generate=True),
])

models = [
    dict(
        abbr="<ABBR>",
        type=OpenAISDK,
        path="<MODEL_PATH>",
        tokenizer_path="<TOKENIZER_PATH>",
        openai_api_base="<OPENAI_API_BASE>",
        key="EMPTY",
        meta_template=api_meta_template,
        temperature=0,
        query_per_second=64,
        max_out_len=16384,
        max_seq_len=32768,
        pred_postprocessor=dict(
            type="opencompass.utils.text_postprocessors.extract_non_reasoning_content"
        ),
        batch_size=32,
    ),
]
```

## 启动模板

OpenCompass 评测必须通过 skill 自带固定脚本启动，避免宿主机/容器路径混用：

```bash
bash <RUN_DIR>/scripts/start_opencompass_safe.sh \
  <TASK_ID> \
  <CONTAINER> \
  /mnt/dcu-llmtest-run/opencompass_configs/<TASK_ID>.py \
  <RUN_DIR> \
  /mnt/dcu-llmtest-run/<TASK_ID>/opencompass \
  <NODE_IP>
```

路径约束：

- `<RUN_DIR>` 是宿主机路径，例如 `/public/home/.../dcu-qwen3-vllm-runs/<timestamp>`。
- `<CONFIG>` 和 `<WORK_DIR>` 是容器路径，必须在 `/mnt/dcu-llmtest-run/...` 下。
- 不得在宿主机执行 `mkdir -p /mnt/dcu-llmtest-run/...`。

续跑/补评估：

```bash
python /workspace/opencompass/run.py <CONFIG> -m eval -r <TIMESTAMP> -w <WORK_DIR>
python /workspace/opencompass/run.py <CONFIG> -m infer -r <TIMESTAMP> -w <WORK_DIR>
```

如果必须使用 `opencompass` 命令，参数保持一致：

```bash
opencompass <CONFIG> -m eval -r <TIMESTAMP> -w <WORK_DIR>
opencompass <CONFIG> -m infer -r <TIMESTAMP> -w <WORK_DIR>
```
