# 推理服务启动流程

本文件用于承接 `SKILL.md` 中的服务脚本准备、启动、日志落盘和一次性 watch 细节。旧模型服务监控脚本已移除，当前使用 `scripts/watch_model_once.sh` 在会话内观察服务与评测状态。

## 目录

- 服务脚本准备
- Cookbook-first 规则
- 本地 vLLM 补充来源
- 本地 SGLang 补充来源
- 已有脚本校验
- 自动生成脚本
- 启动与日志落盘
- 一次性 watch
- 失败排查

## 服务脚本准备

启动模型服务必须优先参考 HYGON-AI cookbook 最佳实践。生成或修改 `serve_<模型名>.sh` 前，先读取 `references/model_deployment_cookbook.md`，并按框架和模型族定位外部最佳实践：

- vLLM: `https://github.com/HYGON-AI/dcu-inference-cookbook/tree/main/docs/model-deployment/vllm`
- SGLang: `https://github.com/HYGON-AI/dcu-inference-cookbook/tree/main/docs/model-deployment/sglang`

执行规则：

1. 先确认或推断推理框架：`vllm` 或 `sglang`。
2. 在 skill 根目录执行 cookbook 缓存检查：`python3 scripts/update_cookbook_cache.py --check`。若用户要求强制更新 cookbook，则改为 `--force`。
3. 根据模型名匹配模型族文档，例如 `qwen3.md`、`qwen3.5.md`、`deepseek-v3.2.md`、`glm-5.md`、`kimi-k2.5.md`。
4. 从 cookbook 中提取匹配条目的环境变量、启动命令、推荐硬件、卡数、TP/PP/DP、dtype、量化方式、上下文长度、显存比例和特殊优化开关。匹配必须对齐模型名/模型变体、框架、卡型、卡数、部署方式和量化方式；模型名先按 `references/model_deployment_cookbook.md` 做规范化精确匹配。若只有模糊候选，必须展示候选差异并等待用户确认，不得自动用相邻模型、相似版本或不同 vLLM/SGLang 版本条目代替。
5. 将 cookbook 命令只做最小适配：添加/设置 `HIP_VISIBLE_DEVICES`、把模型路径替换为目标节点可见的绝对模型路径，以及在端口占用或同节点并发时新增/修改服务监听端口。模型路径默认先从 `/public/opendas/DL_DATA/llm-models/` 下查找；若路径是软链接且解析到 `/public4/...` 等位置，启动命令仍优先保留 `/public/opendas/DL_DATA/llm-models/...` 这一入口路径。不得改写 dtype、TP/PP/DP、量化、`-cc`/编译配置、调度参数、上下文长度、显存比例或其它来源测试设置。
6. 生成脚本时不得删除 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量，也不得额外添加来源方案没有给出的优化环境变量，除非用户明确提供或授权。不得加入或保留 `rm`、`rm -rf`、`rmdir` 等清理命令；cookbook 中出现这些命令时直接省略。
7. 默认使用 IFB；只有用户明确要求 PD 分离模式时才选择 PD 条目或参数。
8. 匹配条目必须同时对齐模型、框架、加速卡型号、卡数、部署方式和量化/模型变体。若模型名仅为后缀差异（例如 `instruct`、`2507`、`channel`、`int8`、`w8a8`），可列出 cookbook 模糊候选并询问用户是否采用；若框架、卡型、卡数、部署方式或量化方式不一致，停止自动生成并询问用户是否提供适配脚本。
9. 只有 cookbook 没有覆盖目标组合，且用户没有确认任何 cookbook 模糊候选时，才回退到对应框架的本地补充测试指导。不得把 cookbook 条目与本地测试指导条目合并；若补充来源也没有精确匹配，直接询问用户提供脚本，用户不能提供则跳过/blocked。

## 本地 vLLM 补充来源

若 HYGON-AI cookbook 未覆盖目标模型，且用户选择 `vllm`，再读取：

- `references/vllm_test_guidance.md`
- `references/VLLM测试指导.md`

卡型别名规范化：

- `NMZ` / `nmz` -> `BW1100` 或 `BW1101`
- `BMZ` / `bmz` / `BW1000` -> `BW1000`
- `KME` / `K100_AI` / `K100AI` -> `K100AI`

若补充文档对应卡型标记为 `暂无`、`不支持`、`有bug`、`待重新测试`、`预估需要双机`，或模型/量化/卡型/卡数/部署方式不是精确匹配，标记 blocked 并询问用户处理方式。

## 本地 SGLang 补充来源

若 HYGON-AI cookbook 未覆盖目标模型，且用户选择 `sglang`，再读取：

- `references/sglang_test_guidance.md`
- `references/SGLANG测试指导.md`

卡型别名规范化：

- `NMZ` / `nmz` -> `BW1100` 或 `BW1101`
- `BMZ` / `bmz` / `BW1000` -> `BW1000`
- `KME` / `K100` / `K100AI` -> `K100AI`

若补充文档对应卡型标记为 `暂无`、`不支持`、`有bug`、`有 bug`、`待重新测试`、`预估需要双机`、`双机`，或模型/量化/卡型/卡数/部署方式不是精确匹配，或出现无法替换的 `<LOCAL_PATH>`/`[internal-link-removed]`，标记 blocked 并询问用户处理方式。除 `HIP_VISIBLE_DEVICES`、模型路径和服务监听端口外，不得替换 `<HOST_IP>`、`master_ip`、`NODE2_IP`、`--dist-init-addr` 等来源设置；这些字段无法直接用于当前环境时标记 blocked 并询问用户。

## 已有脚本校验

优先查找框架感知命名：`serve_<framework>_<模型名>.sh`；兼容旧命名：`serve_<模型名>.sh`。

找到脚本后不要直接启动，先做轻量校验：

- 框架是否一致。
- 模型路径是否为目标节点绝对路径，优先为 `/public/opendas/DL_DATA/llm-models/...` 下存在的目录或软链接。
- TP/卡数、dtype、量化参数是否与 cookbook 冲突。
- cookbook 条目的加速卡型号和部署方式是否与当前环境一致。
- 关键 DCU 环境变量和特殊优化开关是否缺失。
- 服务端口和日志路径是否明确。
- 多模型计划中的服务日志是否写入 `<run_dir>/serve_logs/<task_id>.serve.log`。

若脚本与 cookbook 明显不一致，先展示差异并建议更新；用户确认后再启动。若主要差异是卡型不匹配，直接询问用户是否提供适配脚本。

## 自动生成脚本

未找到脚本时，向用户提供两个选项：

```text
scripts/ 目录下未找到 <模型名> 的启动脚本。请选择：

1. 由您提供脚本内容（直接粘贴或提供路径）
2. 由我参考 HYGON-AI cookbook 最佳实践自动生成一个新脚本
```

### 模型路径查找

用户未提供目标节点模型路径时，先在默认模型根目录查找，不要凭经验拼接不存在的路径：

```bash
ssh <Node_IP> "find /public/opendas/DL_DATA/llm-models -maxdepth 4 \
  \( -type d -o -type l \) -iname '*<MODEL_KEYWORD>*' 2>/dev/null | head -20"
```

选中候选后必须在目标节点校验并记录软链接真实落点：

```bash
ssh <Node_IP> "test -e '<MODEL_PATH>' && echo OK:'<MODEL_PATH>' && readlink -f '<MODEL_PATH>'"
```

生成服务脚本时，启动命令中的模型路径使用 `<MODEL_PATH>` 原路径；若它解析到 `/public4/...`，只在脚本头部写明 `model_realpath`，不要强制替换为真实落点。

自动生成时优先复用 cookbook。严禁混用多个来源；一个脚本只能来自一个 cookbook 条目、一个本地测试指导条目，或用户提供的一份脚本：

- 环境变量区：DCU、NUMA、通信、量化、MoE、PD/IFB、框架专属优化开关。
- 启动命令区：vLLM 的 `vllm serve` 或 SGLang 的 `python3 -m sglang.launch_server`。
- 推荐配置区：框架版本、硬件、卡数、TP/PP/DP、dtype、量化、上下文长度、显存比例、端口。

生成规则：

- 环境变量区和启动参数完整保留来源方案；只允许额外添加/设置 `HIP_VISIBLE_DEVICES`，以及按计划端口设置服务监听端口。
- 模型路径替换为目标节点绝对路径，默认从 `/public/opendas/DL_DATA/llm-models/` 下查找。若模型目录是软链接，使用软链接入口路径即可，并在元信息中记录 `realpath`。
- TP/PP/DP、dtype、量化、上下文长度、显存比例、`-cc`/编译配置等以匹配条目为准，不得为了启动成功做推断或试错改写。端口可为避免冲突或支持同节点并发而自主改写，但必须同步脚本、计划、curl 探活和评测 API base。
- 默认 IFB；只有用户明确要求 PD 时才使用 PD。
- 脚本开头写明模型、框架、cookbook 文件、卡型、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、KVCache、端口、模型绝对路径和软链接真实落点。KVCache 根据服务启动命令判断：包含 `--kv-cache-dtype fp8...` 时写 `kvcache_fp8`，否则写 `default`。
- 若脚本来自用户确认的 cookbook 模糊候选，脚本开头还必须写明 `fuzzy_match: confirmed`、原始目标模型名、候选条目名和差异 token；生成后再次展示给用户确认再保存或启动。
- 不得将 `rm`、`rm -rf`、`rmdir` 等清理命令写入生成脚本；若来源方案包含这些命令，在展示来源信息时说明已按规则省略。
- 服务脚本不应把日志固定写死到容器 `/tmp`。由启动器将 stdout/stderr 重定向到 run 目录挂载路径，例如 `/mnt/dcu-llmtest-run/serve_logs/<task_id>.serve.log`；宿主机对应路径为 `<run_dir>/serve_logs/<task_id>.serve.log`。
- 若来源没有明确卡数、TP 或关键参数，标记 blocked 并询问用户提供脚本；不得根据模型规模、可用卡数或经验推断。

生成后展示脚本全文，用户确认后保存为 `scripts/serve_<模型名>.sh`。

## 启动与日志落盘

将脚本上传到目标节点并在容器内后台运行：

```bash
scp scripts/serve_<模型名>.sh <Node_IP>:/tmp/serve_<模型名>.sh

ssh -tt <Node_IP> "mkdir -p <run_dir>/scripts <run_dir>/serve_logs"

scp scripts/watch_model_once.sh <Node_IP>:<run_dir>/scripts/watch_model_once.sh

ssh -tt <Node_IP> "docker exec -d <container_name> bash -c \
  'bash /tmp/serve_<模型名>.sh > /mnt/dcu-llmtest-run/serve_logs/<task_id>.serve.log 2>&1'"
```

启动后每 2 分钟调用一次 one-shot watch，直到服务 ready、异常或超时。watch 只读取宿主机挂载日志最后 10 行并做 HTTP 探活，不生成状态文件：

```bash
ssh -tt <Node_IP> "bash <run_dir>/scripts/watch_model_once.sh \
  serve <task_id> <run_dir> <container_name> <端口> <vllm|sglang>"
```

最终就绪判定以 HTTP 探活为准：`/health`、`/v1/models`、`/server_info`、`/get_server_info` 中任一端点返回 2xx/3xx 后，先按 `references/accuracy_workflow.md` 执行 `/v1/chat/completions` curl 样本检查；响应正常且无乱码才允许触发测试。

## 失败排查

失败时读取少量日志用于汇报，但不得自动尝试修改参数、切换来源或重启：

```bash
ssh -tt <Node_IP> "bash <run_dir>/scripts/watch_model_once.sh \
  serve <task_id> <run_dir> <container_name> <端口> <vllm|sglang>"
```

只读取宿主机 `<run_dir>/serve_logs/<task_id>.serve.log` 的尾部。不要从容器内复制或生成服务日志。

不要读取完整日志，除非用户明确要求。
