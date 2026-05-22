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
2. 确认模型族：例如 `qwen3`、`qwen3.5`、`deepseek-v3.2`、`glm-5`、`kimi-k2.5`、`minimax`。
3. 确认当前节点加速卡型号，例如 `BW1000`、`BW1100`、`K100_AI`。
4. 默认选择 IFB 部署方式；只有用户明确要求 PD 分离模式时，才选择 PD 相关条目或参数。
5. 在对应目录中定位最佳实践文件，并匹配模型、框架、加速卡型号、卡数和部署方式。
6. 优先复用文档中的环境变量、启动命令、TP/PP/DP 配置、dtype、量化参数、上下文长度、显存比例、调度参数和特殊优化开关。
7. 将 cookbook 命令适配到本 skill 的容器和模型挂载约定：
   - 容器内模型路径通常为 `/model/<模型名>`。
   - 服务日志写入 `/tmp/<framework>_serve.log`。
   - 服务启动后使用 `watch_llm_ready.sh` 写入 `/tmp/llm_status.json`。
8. 若当前节点加速卡型号与 cookbook 条目不一致，不要强行改写命令，直接询问用户是否能够提供适配当前卡型的脚本。
9. 只有在 cookbook 没有覆盖目标模型/框架/卡型/部署方式组合时，才参考 `scripts/serve_*.sh` 中的本地模板或向用户请求脚本。

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

## 临时读取方式

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
- 若 cookbook 中的模型路径是 ModelScope/HuggingFace ID，而本地容器使用 `/model/<模型名>`，只替换模型路径，不改其他优化参数。
- vLLM 常见端口为 `8000`，SGLang 常见端口为 `30000`；若用户脚本或 cookbook 明确指定端口，以指定端口为准。
- SGLang 启动命令通常为 `python3 -m sglang.launch_server` 或 `python -m sglang.launch_server`。
- vLLM 启动命令通常为 `vllm serve`。
- 生成脚本开头必须写明启动命令元信息：模型、框架、cookbook 文件、加速卡型号、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- 生成脚本后必须向用户展示关键差异：引用的 cookbook 文件、匹配的模型条目、当前节点卡型、cookbook 卡型、部署方式、卡数/TP、dtype、量化方式、端口、被保留的关键环境变量。
