# VLLM 测试指导补充来源

本文件记录本地补充文档 `VLLM测试指导.md` 的使用规则。该文档用于补充 HYGON-AI cookbook 未覆盖的模型测试方案。

## 来源文件

- Skill 内置副本：`references/VLLM测试指导.md`
- 原始来源：`/public/home/wanghy18/acc/VLLM测试指导.docx`
- 适用框架：主要用于 `vllm`

## 使用优先级

启动脚本和测试方案查找顺序：

1. 优先查 HYGON-AI `dcu-inference-cookbook/docs/model-deployment/`。
2. 如果 GitHub cookbook 没有涉及目标模型/卡型/部署方式，再查 `references/VLLM测试指导.md`。
3. 如果 Markdown 补充文档也找不到目标模型，或目标卡型标记为暂无/不支持/有 bug，则询问用户是否能够提供适配脚本。

不要在 cookbook 已明确覆盖且卡型匹配时，擅自用本地补充文档覆盖 cookbook 的最佳实践。本地测试指导是补充来源，不是主来源。不得把 cookbook 条目与本地测试指导条目合并生成脚本。

## 加速卡别名映射

补充文档中的集群/卡型标记必须规范化：

| 文档标记 | 规范卡型 |
|-----------|----------|
| `NMZ` / `nmz` | `BW1100` 或 `BW1101` |
| `BMZ` / `bmz` / `BW1000` | `BW1000` |
| `KME` / `K100_AI` / `K100AI` | `K100AI` |

当用户指定 `NMZ` 时，视为 BW1100/BW1101 系列；当用户指定 `BMZ` 时，视为 BW1000；当用户指定 `KME` 时，视为 K100AI。

## 读取方式

需要查询具体模型时，直接在 Markdown 中定位模型标题：

```bash
rg -n '^## .*<模型名>|^#### (BW1000|NMZ|K100_AI|KME)' references/VLLM测试指导.md
```

定位后按文档结构解析，并要求精确匹配模型名/量化版本、测试模式、卡型、卡数和部署方式：

- 模型为二级标题。
- 测试模式为三级标题。
- 加速卡为四级标题。
- 通用启动命令通常在“测试模式”下。
- 卡型差异参数通常在 `BW1000`、`NMZ`、`K100_AI` 等小节下。

生成脚本时，仅允许将同一模型条目内的通用测试模式命令和目标卡型小节补充参数合并；不得引入 cookbook、其它模型、其它量化版本或历史脚本的参数。最终脚本除添加/设置 `HIP_VISIBLE_DEVICES`、替换模型路径和按需设置服务端口外，不得修改来源测试设置。模型路径优先使用目标节点 `/public/opendas/DL_DATA/llm-models/...` 下的绝对路径，允许软链接解析到 `/public4/...`；来源中的 `rm`、`rm -rf`、`rmdir` 等清理命令必须省略。

## 模型索引

当前 Markdown 已出现以下模型条目：

- `Kimi-K2.5-w4a16`
- `Qwen3-30B-A3B`
- `Qwen3-8B`
- `Qwen3-8B.w8a8`
- `Qwen3-30B-A3B.w8a8`
- `Qwen3-VL-235B-A22B-Thinking`
- `DeepSeek-V3.2-Channel-INT8`
- `DeepSeek-V3.2-channel-fp8`
- `Qwen3-235B-A22B`
- `Qwen3-235B-A22B-W8A8`
- `Qwen3-235B-A22B-Instruct-2507`
- `Qwen3-32B-W8A8`
- `MiniMax-M2.5-W8A8`
- `MiniMax-M2_5-Channel-FP8-w8a8`
- `MiniMax-M2.5-bf16`
- `Qwen3-32B`
- `Qwen2.5-VL-72B-Instruct`
- `Qwen2.5-VL-72B-Instruct-quantized.w8a8`
- `GLM-5-w4a8-V2_6_test`
- `GLM-5-W8A8`
- `GLM5-Channelwise-FP8-quantized`
- `DeepSeek-R1-Distill-Llama-70B`
- `DeepSeek-R1-Distill-Qwen-32B`
- `GLM4.7-w8a8`
- `GLM5.1-Channel-INT8`
- `GLM5.1-Channel-FP8`
- `Qwen3-VL-30B-A3B-Thinking`
- `DeepSeek-R1-Channel-INT8`
- `DeepSeek-R1-Channe-FP8`
- `Qwen3-VL-235B-A22B-Instruct`
- `Qwen3-Coder-480B-A35B-Instruct-w8a8`
- `Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic`
- `DeepSeek-R1-0528-W4A8-V2`
- `Qwen3-4B-Thinking-2507`
- `QwQ-32B`
- `DeepSeek-R1-bf16`
- `Qwen3-Next-80B-A3B-Instruct`
- `Qwen3-0.6B`
- `Qwen3-4B`
- `Qwen3.5-122B-A10B`
- `GLM-4-32B-0414`
- `DeepSeek-V3.1-Terminus-fp8`
- `DeepSeek-R1-Distill-Llama-70B-quantized.w8a8`
- `Qwen3.5-35B-A3B`
- `Qwen3.5-35B-A3B-W8A8`
- `DeepSeek-V3-W4A8-V2`
- `Qwen3-VL-32B-Instruct`
- `Qwen2.5-VL-32B-Instruct`
- `Qwen3-VL-4B-Instruct`

## 状态词处理

如果目标卡型小节出现以下内容，按 blocked 处理：

- `暂无`
- `不支持`
- `有bug`
- `待重新测试`
- `预估需要双机`

blocked 任务不要自动排入执行计划，应向用户说明原因并询问是否提供脚本、换卡型或跳过。

## 生成脚本要求

从本地测试指导生成启动脚本时仍然遵守 skill 主规则：

- 脚本开头写明模型、框架、来源文件、加速卡型号、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- 不删除 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量，也不新增来源中没有的优化环境变量或参数。
- 默认 IFB，只有用户明确要求时才使用 PD 分离模式。
- 模型路径统一替换为目标节点绝对路径，优先从 `/public/opendas/DL_DATA/llm-models/` 查找；若路径是软链接，启动命令仍使用软链接入口路径。
- 端口必须沿用来源文档或框架默认值；发现端口冲突时标记 blocked/异常并询问用户，不自动改写端口。
- 若文档中的模型需要多节点或超过 8 卡，当前版本标记为 blocked，因为本 skill 暂只支持单机模型。
