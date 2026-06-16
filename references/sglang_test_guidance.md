# SGLang 测试指导补充来源

本文件记录本地补充文档 `SGLANG测试指导.md` 的使用规则。该文档用于补充 HYGON-AI cookbook 未覆盖的 SGLang 模型测试方案。

## 来源文件

- Skill 内置副本：`references/SGLANG测试指导.md`
- 原始来源：`/public/home/wanghy18/acc/SGLANG测试指导.md`
- 适用框架：仅用于 `sglang`
- 脱敏处理：已移除人员标记、内网 IP、内部链接、内部主目录/日志路径和 shell prompt，仅保留模型测试方案信息。

## 使用优先级

启动脚本和测试方案查找顺序：

1. 优先查 HYGON-AI `dcu-inference-cookbook/docs/model-deployment/sglang/`。
2. 如果 GitHub cookbook 没有涉及目标模型/卡型/部署方式，再查 `references/SGLANG测试指导.md`。
3. 如果 Markdown 补充文档也找不到目标模型，或目标卡型标记为暂无/不支持/有 bug，则询问用户是否能够提供适配脚本。

不要在 cookbook 已明确覆盖且卡型匹配时，擅自用本地补充文档覆盖 cookbook 的最佳实践。本地测试指导是补充来源，不是主来源。不得把 cookbook 条目与本地测试指导条目合并生成脚本。

## 加速卡别名映射

补充文档中的集群/卡型标记必须规范化：

| 文档标记 | 规范卡型 |
|-----------|----------|
| `NMZ` / `nmz` | `BW1100` 或 `BW1101` |
| `BMZ` / `bmz` / `BW1000` | `BW1000` |
| `KME` / `K100` / `K100AI` | `K100AI` |

当用户指定 `NMZ` 时，视为 BW1100/BW1101 系列；当用户指定 `BMZ` 时，视为 BW1000；当用户指定 `KME` 或 `K100` 时，视为 K100AI。

## 读取方式

需要查询具体模型时，直接在 Markdown 中定位模型标题：

```bash
rg -n '^## .*<模型名>|^####? (BW1000|BMZ|NMZ|nmz|KME|K100|K100AI)' references/SGLANG测试指导.md
```

定位后按文档结构解析，并要求精确匹配模型名/量化版本、测试模式、卡型、卡数和部署方式：

- 模型为二级标题。
- 测试模式通常为三级标题。
- 加速卡为三级或四级标题，原文中同时存在 `### NMZ` 和 `#### NMZ` 两种写法。
- 通用启动命令通常在“测试模式”下。
- 卡型差异参数通常在 `NMZ`、`BW1000`、`BMZ`、`KME`、`K100AI` 等小节下。

生成脚本时，仅允许将同一模型条目内的通用测试模式命令和目标卡型小节补充参数合并；不得引入 cookbook、其它模型、其它量化版本或历史脚本的参数。最终脚本除添加/设置 `HIP_VISIBLE_DEVICES` 和替换模型路径外，不得修改来源测试设置。文档中出现 `<HOST_IP>`、`master_ip`、`NODE2_IP`、`--dist-init-addr`、端口等无法直接用于当前环境的字段时，按 blocked 说明处理并询问用户，不自动替换。

## 模型索引

当前 Markdown 已出现以下模型条目：

- `MiniMax-M2.5-Channel-INT8-w8a8`
- `MiniMax-M2___5-Channel-FP8-w8a8`
- `MiniMax-M2.5-bf16`
- `Qwen2.5-VL-72B-Instruct`
- `GLM5-Channelwise-FP8-quantized`
- `GLM-5-W8A8`
- `GLM-5-w4a8`
- `GLM-5.1-FP8`
- `GLM-5.1-W8A8`
- `GLM-5.1-w4a8`
- `Ling-T-FP8`
- `Qwen3.5-397B`
- `Qwen3.5-397B-A17B-Channel-FP8`
- `Qwen3.5-397B-A17B-W8A8`
- `MiMo-V2-Flash`
- `MiMo-V2-Flash-Channel-FP8-w8a8`
- `MiMo-V2-Flash-Channel-INT8-w8a8`
- `Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic`
- `Qwen3-Coder-480B-A35B-Instruct-w8a8`
- `Qwen3-VL-235B-A22B-Instruct`
- `Qwen3-30B-A3B-bf16`
- `Qwen3-30B-A3B-w8a8`
- `DeepSeek-R1-Distill-Llama-70B`
- `DeepSeek-R1-Distill-Llama-70B-int8`
- `Qwen3.5-27B`
- `Qwen3.6-27B`
- `Qwen3.6-27B-W8A8`
- `Qwen3-235b-a22b-instruct-2507`
- `Qwen3-4B-Thinking-2507`
- `DeepSeek-R1-Channel-INT8`
- `DeepSeek-R1-Channel-FP8`
- `Qwen3-VL-30B-A3B-Thinking`
- `DeepSeek-R1-Distill-Qwen-32B`
- `Qwen3-Next-80B-A3B-Instruct`
- `QwQ-32B`
- `Qwen3-235B-A22B-W8A8`
- `Qwen3-VL-4B-Instruct`
- `Qwen2.5-VL-72B-Instruct-quantized.w8a8`
- `GLM-4-32B-0414`
- `deepseek-v3.1-terminus`
- `DeepSeek-R1-0528-W4A8-V2`
- `DeepSeek-V3-0324`
- `Qwen3.5-122B-A10B`
- `Qwen3-8B`
- `Qwen3-8B.w8a8`
- `Kimi-K2.5/2.6`
- `Qwen3.5-122B-A10B-W8A8`
- `Qwen3.5-122B-A10B-Channel-FP8`
- `DeepSeek-V3-W4A8-V2`
- `Qwen3-VL-32B-Instruct`
- `Qwen2.5-VL-32B-Instruct`

## 状态词处理

如果目标卡型小节出现以下内容，按 blocked 处理：

- `暂无`
- `不支持`
- `有bug`
- `有 bug`
- `待重新测试`
- `预估需要双机`
- `双机`
- `<LOCAL_PATH>` 且缺少可替换的模型路径
- `[internal-link-removed]` 且该链接是问题原因的唯一说明

blocked 任务不要自动排入执行计划，应向用户说明原因并询问是否提供脚本、换卡型或跳过。若文档中明确需要双机或 `--nnodes 2`，当前版本默认标记为 blocked，因为本 skill 暂只支持单机模型。

## 生成脚本要求

从本地测试指导生成启动脚本时仍然遵守 skill 主规则：

- 脚本开头写明模型、框架、来源文件、加速卡型号、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- 不删除 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量，也不新增来源中没有的优化环境变量或参数。
- 默认 IFB，只有用户明确要求时才使用 PD 分离模式。
- 模型路径统一替换为容器内 `/model/<模型名>`，不要沿用文档里的 `<LOCAL_PATH>` 或历史目录。
- `host_ip`、`master_ip`、`NODE2_IP`、`--dist-init-addr` 等字段不得自动改写；当前环境无法原样使用时标记 blocked 并询问用户。
- 端口必须沿用来源文档或框架默认值；发现端口冲突时标记 blocked/异常并询问用户，不自动改写端口。
- 若文档中的模型需要多节点或超过 8 卡，当前版本标记为 blocked，因为本 skill 暂只支持单机模型。
