# 精度评测框架安装与选择

精度测试前，先让用户选择评测工具：

1. `evalscope`：默认推荐，适合 OpenAI-compatible API 快速评测。
2. `opencompass`：适合需要 OpenCompass 数据集、配置和报告体系的正式评测。

如果用户没有指定，默认使用 `evalscope`。如果用户要求和既有 OpenCompass 数据集/配置保持一致，则选择 `opencompass`。

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

若需要 API 模型评测，额外确认 OpenAI-compatible 依赖是否可用：

```bash
pip install openai
```

安装后验证：

```bash
pip list | grep -E 'opencompass|openai'
python -m opencompass --help
```

## 工具选择规则

- 用户说“快速精度测试”“先跑少量样本”“OpenAI API 方式”时，优先 `evalscope`。
- 用户说“OpenCompass”“正式报告”“复用 opencompass 数据集/配置”时，选择 `opencompass`。
- 如果两者都未安装，先询问用户选择哪个工具，再安装对应工具。
- 如果用户不确定，建议先用 `evalscope` 跑小样本，再根据需要切换到 `opencompass` 做正式评测。

## 数据集准备

- `evalscope` 默认数据集路径约定：`/mnt/opencompass/data/<数据集名>`。
- `opencompass` 默认优先使用 OpenCompass 工程内配置和数据集路径。
- 如果数据集不存在，不要自动下载大数据集；先向用户确认数据集来源、路径和是否允许下载。
