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

优先使用挂载的 OpenCompass 工程，并设置数据集缓存和代理排除：

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
export no_proxy=<NODE_IP>,localhost,127.0.0.1
export NO_PROXY=<NODE_IP>,localhost,127.0.0.1
export COMPASS_DATA_CACHE=/mnt/opencompass
export PYTHONPATH=/mnt/opencompass:${PYTHONPATH:-}

cd <RUN_DIR>
if [ -f /mnt/opencompass/run.py ]; then
  python /mnt/opencompass/run.py <CONFIG>
else
  opencompass <CONFIG>
fi
```

续跑/补评估：

```bash
python /mnt/opencompass/run.py <CONFIG> -m eval -r <TIMESTAMP> -w <WORK_DIR>
python /mnt/opencompass/run.py <CONFIG> -m infer -r <TIMESTAMP> -w <WORK_DIR>
```

如果必须使用 `opencompass` 命令，参数保持一致：

```bash
opencompass <CONFIG> -m eval -r <TIMESTAMP> -w <WORK_DIR>
opencompass <CONFIG> -m infer -r <TIMESTAMP> -w <WORK_DIR>
```
