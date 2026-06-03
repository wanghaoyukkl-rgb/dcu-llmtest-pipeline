# 推理服务启动与监控流程

本文件用于承接 `SKILL.md` 中的服务脚本准备、启动和低 token 监控细节。用户要启动、调整或排查 vLLM/SGLang 服务时读取。

## 目录

- 服务脚本准备
- Cookbook-first 规则
- 本地 vLLM 补充来源
- 本地 SGLang 补充来源
- 已有脚本校验
- 自动生成脚本
- 启动与 watcher 监控
- 状态处理与失败排查

## 服务脚本准备

启动模型服务必须优先参考 HYGON-AI cookbook 最佳实践。生成或修改 `serve_<模型名>.sh` 前，先读取 `references/model_deployment_cookbook.md`，并按框架和模型族定位外部最佳实践：

- vLLM: `https://github.com/HYGON-AI/dcu-inference-cookbook/tree/main/docs/model-deployment/vllm`
- SGLang: `https://github.com/HYGON-AI/dcu-inference-cookbook/tree/main/docs/model-deployment/sglang`

执行规则：

1. 先确认或推断推理框架：`vllm` 或 `sglang`。
2. 在 skill 根目录执行 cookbook 缓存检查：`python3 scripts/update_cookbook_cache.py --check`。若用户要求强制更新 cookbook，则改为 `--force`。
3. 根据模型名匹配模型族文档，例如 `qwen3.md`、`qwen3.5.md`、`deepseek-v3.2.md`、`glm-5.md`、`kimi-k2.5.md`。
4. 从 cookbook 中提取匹配条目的环境变量、启动命令、推荐硬件、卡数、TP/PP/DP、dtype、量化方式、上下文长度、显存比例和特殊优化开关。
5. 将 cookbook 命令适配到当前容器路径和端口约定；模型路径统一为 `/model/<模型名>`。
6. 生成脚本时不得删除 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量。
7. 默认使用 IFB；只有用户明确要求 PD 分离模式时才选择 PD 条目或参数。
8. 匹配条目必须同时对齐模型、框架、加速卡型号、卡数和部署方式。若当前卡型与 cookbook 条目不一致，停止自动改写并询问用户是否提供适配脚本。
9. 只有 cookbook 没有覆盖目标组合时，才回退到对应框架的本地补充测试指导、已有本地脚本模板，或请求用户提供脚本。

## 本地 vLLM 补充来源

若 HYGON-AI cookbook 未覆盖目标模型，且用户选择 `vllm`，再读取：

- `references/vllm_test_guidance.md`
- `references/VLLM测试指导.md`

卡型别名规范化：

- `NMZ` / `nmz` -> `BW1100` 或 `BW1101`
- `BMZ` / `bmz` / `BW1000` -> `BW1000`
- `KME` / `K100_AI` / `K100AI` -> `K100AI`

若补充文档对应卡型标记为 `暂无`、`不支持`、`有bug`、`待重新测试`、`预估需要双机`，标记 blocked 并询问用户处理方式。

## 本地 SGLang 补充来源

若 HYGON-AI cookbook 未覆盖目标模型，且用户选择 `sglang`，再读取：

- `references/sglang_test_guidance.md`
- `references/SGLANG测试指导.md`

卡型别名规范化：

- `NMZ` / `nmz` -> `BW1100` 或 `BW1101`
- `BMZ` / `bmz` / `BW1000` -> `BW1000`
- `KME` / `K100` / `K100AI` -> `K100AI`

若补充文档对应卡型标记为 `暂无`、`不支持`、`有bug`、`有 bug`、`待重新测试`、`预估需要双机`、`双机`，或出现无法替换的 `<LOCAL_PATH>`/`[internal-link-removed]`，标记 blocked 并询问用户处理方式。文档中的 `<HOST_IP>`、`master_ip`、`NODE2_IP`、`--dist-init-addr`、端口和模型路径必须按当前任务重新生成。

## 已有脚本校验

优先查找框架感知命名：`serve_<framework>_<模型名>.sh`；兼容旧命名：`serve_<模型名>.sh`。

找到脚本后不要直接启动，先做轻量校验：

- 框架是否一致。
- 模型路径是否为 `/model/<模型名>`。
- TP/卡数、dtype、量化参数是否与 cookbook 冲突。
- cookbook 条目的加速卡型号和部署方式是否与当前环境一致。
- 关键 DCU 环境变量和特殊优化开关是否缺失。
- 服务端口和日志路径是否明确。

若脚本与 cookbook 明显不一致，先展示差异并建议更新；用户确认后再启动。若主要差异是卡型不匹配，直接询问用户是否提供适配脚本。

## 自动生成脚本

未找到脚本时，向用户提供两个选项：

```text
scripts/ 目录下未找到 <模型名> 的启动脚本。请选择：

1. 由您提供脚本内容（直接粘贴或提供路径）
2. 由我参考 HYGON-AI cookbook 最佳实践自动生成一个新脚本
```

自动生成时优先复用 cookbook：

- 环境变量区：DCU、NUMA、通信、量化、MoE、PD/IFB、框架专属优化开关。
- 启动命令区：vLLM 的 `vllm serve` 或 SGLang 的 `python3 -m sglang.launch_server`。
- 推荐配置区：框架版本、硬件、卡数、TP/PP/DP、dtype、量化、上下文长度、显存比例、端口。

生成规则：

- 环境变量区完整保留，不得删改 cookbook 和 `references/rules/dcu_adaptation_rules.md` 中的 DCU 底层环境变量。
- 模型路径替换为 `/model/<模型名>`。
- TP/PP/DP、dtype、量化、上下文长度、显存比例等以匹配条目为准。
- 默认 IFB；只有用户明确要求 PD 时才使用 PD。
- 脚本开头写明模型、框架、cookbook 文件、卡型、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- vLLM 默认日志建议 `/tmp/vllm_serve.log`；SGLang 默认日志建议 `/tmp/sglang_serve.log`。
- 若 cookbook 没有目标规模的明确 TP，才根据模型规模、可用卡数、卡型和用户目标推断，并说明依据。

生成后展示脚本全文，用户确认后保存为 `scripts/serve_<模型名>.sh`。

## 启动与 watcher 监控

将脚本上传到目标节点并在容器内后台运行：

```bash
scp scripts/serve_<模型名>.sh <Node_IP>:/tmp/serve_<模型名>.sh

ssh -tt <Node_IP> "docker exec -d <container_name> bash -c \
  'bash /tmp/serve_<模型名>.sh > <日志路径> 2>&1'"
```

服务启动后立即启动宿主机 watcher，不在 Agent 会话里反复读完整日志：

```bash
scp scripts/watch_llm_ready.sh <Node_IP>:/tmp/watch_llm_ready.sh

ssh -tt <Node_IP> "nohup bash /tmp/watch_llm_ready.sh \
  <container_name> \
  <日志路径> \
  /tmp/llm_status.json \
  <端口> \
  <vllm|sglang> \
  '/health,/v1/models,/server_info,/get_server_info' \
  > /tmp/watch_llm_ready.monitor.log 2>&1 & echo 监控进程PID: $!"
```

最终就绪判定以 HTTP 探活为准：`/health`、`/v1/models`、`/server_info`、`/get_server_info` 中任一端点返回 2xx/3xx 后，先按 `references/accuracy_workflow.md` 执行 `/v1/chat/completions` curl 样本检查；响应正常且无乱码才允许触发测试。

## 状态处理与失败排查

Agent 正常每 30-60 秒只读取状态文件：

```bash
ssh -tt <Node_IP> "cat /tmp/llm_status.json"
```

状态处理：

| status | 含义 | 操作 |
|--------|------|------|
| `starting` | 服务加载中 | 展示 `message` 和 `last_check`，继续等待 |
| `almost_ready` | 日志接近就绪，HTTP 未确认 | 继续等待 |
| `ready` | HTTP 探活已通过 | 先执行 curl 样本检查，通过后进入测试 |
| `error` | 检测到错误 | 展示 `detail`，询问是否排查或重启 |
| `timeout` | 超过 30 分钟未就绪 | 展示 `detail` 和建议操作 |

只有 `status == "ready"` 且 curl 样本检查通过时，才能触发精度/性能测试。

失败或超时时再读取少量日志：

```bash
ssh -tt <Node_IP> "docker exec <container_name> tail -n 80 <日志路径>"
```

不要读取完整日志，除非用户明确要求。
