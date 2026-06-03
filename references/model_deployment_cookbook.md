# HYGON-AI DCU 模型部署最佳实践索引

本文件记录模型服务启动脚本生成时必须优先参考的外部最佳实践来源。

## 来源

- GitHub: `https://github.com/HYGON-AI/dcu-inference-cookbook`
- 目标路径: `docs/model-deployment/`
- vLLM 最佳实践: `docs/model-deployment/vllm/`
- SGLang 最佳实践: `docs/model-deployment/sglang/`

## 使用原则

生成或修改模型服务启动脚本前，必须先根据用户选择的推理框架和模型族读取 cookbook 中对应文档：

1. 确认框架：`vllm` 或 `sglang`。
2. 在读取 cookbook 前先执行缓存检查：`python3 scripts/update_cookbook_cache.py --check`。若状态显示超过 3 天或本地缺失，该脚本会自动 clone/pull GitHub cookbook，并记录本次更新日期。
3. 若用户明确要求“更新 cookbook”“重新拉取 cookbook”“强制更新”，执行 `python3 scripts/update_cookbook_cache.py --force`，不受 3 天 TTL 限制。
4. 确认模型族：例如 `qwen3`、`qwen3.5`、`deepseek-v3.2`、`glm-5`、`kimi-k2.5`、`minimax`。
5. 确认当前节点加速卡型号，例如 `BW1000`、`BW1100`、`K100_AI`。
6. 默认选择 IFB 部署方式；只有用户明确要求 PD 分离模式时，才选择 PD 相关条目或参数。
7. 在缓存目录的对应文件中定位最佳实践文件，并匹配模型、框架、加速卡型号、卡数和部署方式。
8. 优先复用文档中的环境变量、启动命令、TP/PP/DP 配置、dtype、量化参数、上下文长度、显存比例、调度参数和特殊优化开关。
9. 将 cookbook 命令适配到本 skill 的容器和模型挂载约定：
   - 容器内模型路径固定为 `/model/<模型名>`，由容器创建时 `-v <宿主模型路径>:/model/<模型名>:ro` 保证。
   - vLLM 和 SGLang 启动命令中的 model path 都必须使用 `/model/<模型名>`，不得直接使用宿主机路径。
   - 服务日志写入 `/tmp/<framework>_serve.log`。
   - 服务启动后使用 `watch_llm_ready.sh` 写入 `/tmp/llm_status.json`。
10. 若当前节点加速卡型号与 cookbook 条目不一致，不要强行改写命令，优先询问用户是否可以换用匹配卡型节点或提供适配当前卡型的脚本。
11. 只有在 cookbook 没有覆盖目标模型/框架/卡型/部署方式组合时，才进入补充来源：
   - `vllm` 框架：读取 `references/vllm_test_guidance.md` 和 `references/VLLM测试指导.md` 查找补充测试方案。
   - `sglang` 框架：读取 `references/sglang_test_guidance.md` 和 `references/SGLANG测试指导.md` 查找补充测试方案。
12. 如果补充来源仍找不到目标模型/卡型/部署方式，才参考 `scripts/serve_*.sh` 中的本地模板或请求用户提供脚本。

## 当前已确认的 cookbook 文件

### vLLM

- `vllm/deepseek-v3.2.md`
- `vllm/deepseek-v3.md`
- `vllm/glm-5.md`
- `vllm/kimi-k2.5.md`
- `vllm/kimi-k2.md`
- `vllm/minimax-2.x.md`
- `vllm/qwen3-vl.md`
- `vllm/qwen3.5.md`
- `vllm/qwen3.md`

### SGLang

- `sglang/deepseek-r1.md`
- `sglang/deepseek-v3.2.md`
- `sglang/glm-5.md`
- `sglang/kimi-k2.5.md`
- `sglang/kimi-k2.md`
- `sglang/mimo-v2-flash.md`
- `sglang/minimax-m2.5.md`
- `sglang/qwen3.5.md`
- `sglang/qwen3.6.md`
- `sglang/qwen3.md`

## 缓存与自动更新

默认缓存位置：

- cookbook 缓存目录：`~/.cache/dcu-llmtest-pipeline/dcu-inference-cookbook`
- 更新状态文件：`~/.cache/dcu-llmtest-pipeline/cookbook_state.json`
- 稀疏读取路径：`docs/model-deployment`

每次要读取 cookbook 生成/校验服务脚本，或用户被唤醒后继续精度测试且需要查询模型部署方案时，在 skill 根目录先运行：

```bash
python3 scripts/update_cookbook_cache.py --check
```

该命令的行为：

- 若本地没有缓存，clone GitHub cookbook。
- 若 `cookbook_state.json` 中记录的 `last_update_utc` 距当前时间超过 3 天，执行 `git pull --ff-only --depth 1 origin main`。
- 若未超过 3 天，只刷新 `last_checked_utc`，不访问 GitHub 更新内容。
- 每次实际更新后记录 `last_update_utc`、`last_update_epoch`、`head_commit`、`head_commit_date`。

用户明确要求更新 cookbook 时运行：

```bash
python3 scripts/update_cookbook_cache.py --force
```

需要只查看状态、不更新时运行：

```bash
python3 scripts/update_cookbook_cache.py --status
```

读取路径示例：

```bash
sed -n '1,220p' ~/.cache/dcu-llmtest-pipeline/dcu-inference-cookbook/docs/model-deployment/vllm/qwen3.md
sed -n '1,220p' ~/.cache/dcu-llmtest-pipeline/dcu-inference-cookbook/docs/model-deployment/sglang/qwen3.md
```

若 `--check` 或 `--force` 因网络/GitHub 不可用失败：

- 若本地已有缓存，可告知用户更新失败并临时使用现有缓存，同时在计划/报告中标明 cookbook 更新时间和更新失败原因。
- 若本地没有缓存，不能假装已查 cookbook；改为询问用户是否允许稍后重试、提供脚本，或走本地补充测试指导。

## 手动读取方式

若本地没有 cookbook 缓存，可临时克隆到 `/tmp` 后只读取目标路径：

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/HYGON-AI/dcu-inference-cookbook.git /tmp/dcu-inference-cookbook
cd /tmp/dcu-inference-cookbook
git sparse-checkout set docs/model-deployment
```

读取路径示例：

```bash
sed -n '1,220p' /tmp/dcu-inference-cookbook/docs/model-deployment/vllm/qwen3.md
sed -n '1,220p' /tmp/dcu-inference-cookbook/docs/model-deployment/sglang/qwen3.md
```

## 适配规则

- 不得删除 cookbook 中与 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关的环境变量，除非用户明确要求。
- 若 cookbook 中的模型路径是 ModelScope/HuggingFace ID 或其他历史路径，而本地容器使用 `/model/<模型名>`，只替换模型路径，不改其他优化参数。
- vLLM 常见端口为 `8000`，SGLang 常见端口为 `30000`；若用户脚本或 cookbook 明确指定端口，以指定端口为准。
- SGLang 启动命令通常为 `python3 -m sglang.launch_server` 或 `python -m sglang.launch_server`。
- vLLM 启动命令通常为 `vllm serve`。
- 生成脚本开头必须写明启动命令元信息：模型、框架、cookbook 文件、加速卡型号、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- 若启动方案来自本地补充来源，元信息中的来源文件写为 `references/VLLM测试指导.md` 或 `references/SGLANG测试指导.md`，并写明模型标题和卡型小节。
- 生成脚本后必须向用户展示关键差异：引用的 cookbook 文件或本地补充来源、匹配的模型条目、当前节点卡型、来源卡型、部署方式、卡数/TP、dtype、量化方式、端口、被保留的关键环境变量。
