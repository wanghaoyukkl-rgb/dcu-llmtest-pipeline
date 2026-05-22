---
name: dcu-llmtest-pipeline
description: DCU模型推理全流程自动化工具。目前支持模式：1)通用完整流程模式(查找可用资源→生成脚本→推理→数据整理)；2)高自定义模式（查找可用资源→配置环境→根据提供的脚本和参数来进行推理和汇报）；3)多模型自动计划模式（查找节点资源→收集模型/卡型/测试类型→查询启动资源需求→生成并确认并行/串行计划表→按波次执行）。当用户提到"模型推理"、"性能测试"、"精度测试"、"批量测试"、"多个模型"、"计划表"时使用此skill。
version: "0.5.7-alpha"
---

# DCU 推理全流程 Skill

当前版本：**v0.5.7-alpha**。版本特性和边界已移入 `references/current_version.md`，仅在用户询问版本能力或维护 skill 时读取。

作为高级 AI 测试工程师的辅助助手，本 skill 支持三种工作模式，在开始时请先向用户确认选择哪种模式。

## 模式选择

调用此 skill 时，首先询问用户：

**请选择工作模式：**

1. **通用完整流程**：查找可用资源→生成脚本→推理→数据整理（单机/多机）
2. **高自定义**：查找可用资源→配置环境→根据提供的脚本和参数来进行推理和汇报（单机/多机）
3. **多模型自动计划**：查找节点资源→收集模型/卡型/测试类型→查询启动资源需求→生成并确认并行/串行计划表→按波次执行（当前仅单机模型）

---

# 模式一：完整流程

完整流程将查找可用资源、生成脚本、推理、数据整理串联起来。

## 第一步：模型参数收集与计算

### 1.1 查询当前可使用节点环境
从节点 IP 列表中查询当前空闲节点和对应的可用卡数型号以及基本信息，从references/node/nodes.md中获取当前可用节点信息，并通过ssh命令查询节点的占用情况、频率情况、驱动版本和加速卡型号等信息，整理成表格形式返回给用户。

### 1.2 多模型自动计划编排

当用户提出多个模型、批量测试、多个节点并行/串行、生成计划表等需求时，必须先读取 `references/auto_test_plan.md` 并进入自动计划模式。

自动计划模式必须遵守：

- 第一步仍然是查询可用节点资源，输出节点资源表。
- 第二步从用户获取需要测试的模型列表、测试类型、精度数据集队列、目标加速卡型号、推理框架、部署模式、每个模型在目标节点上的宿主机路径和数据集宿主机路径；部署模式默认 `IFB`，只有用户要求时才使用 `PD` 分离模式。
- 第三步按 `references/model_deployment_cookbook.md` 查询每个模型启动服务脚本所需的加速卡型号和卡数。
- 第四步编排计划表：同一节点可并行多个模型，但并行任务卡数之和不能超过节点空闲卡数；一个节点默认 8 张卡；暂不考虑一个模型跨多个节点。
- 第五步为每个任务分配唯一端口，端口在计划表中不能重复；执行时若发现端口占用，必须重新分配并同步更新计划表和启动脚本。
- 第六步将计划表推送给用户确认或修改。用户确认前不得创建容器、启动服务或执行测试。

计划表至少包含：任务ID、波次、模型、框架、测试类型、数据集队列、目标卡型、节点、卡数、卡ID、部署模式、端口、宿主模型路径、容器模型路径、容器名、cookbook条目、状态、备注。

若 cookbook 要求的卡型/卡数与当前资源不对齐，标记为 blocked，并询问用户是否能够提供适配脚本或修改目标卡型/节点。


## 第二步：搭建测试环境

### 2.1 容器创建
根据 `references/container/create_docker_container.md` 在上一步指定的节点上创建容器，返回创建好的容器名和模型挂载关系。

创建容器前必须确认：

- 模型名：用于容器内路径 `/model/<模型名>`，必须与后续服务启动脚本中的 model path 一致。
- 推理框架：`vllm` 或 `sglang`。
- 当前测试加速卡型号：例如 `BW1100`、`BW1000`、`K100AI`。
- 用户提供的目标节点宿主机模型目录：例如 `/public/opendas/DL_DATA/llm-models/Qwen3-32B`。若用户未提供，不要猜测路径，先询问用户。
- 若包含精度测试，确认数据集宿主机目录。默认使用 `/public/home/wanghy18/opencompass/data`；若目标节点不存在该目录，先向用户索要数据集路径。

容器创建规则：

- 容器名固定为 `<加速卡型号>-<YYYYMMDD>-<模型名>-<框架名>`，必要时将模型名中的 `/` 和空格替换为 `-`。
- 必须使用 `docker run -itd` 创建后台容器，不使用 `docker run -it`。
- 模型目录必须按 `-v <宿主机模型目录>:/model/<模型名>:ro` 只读挂载。
- 若包含精度测试，数据集目录必须按 `-v <数据集宿主机目录>:/mnt/opencompass/data:ro` 只读挂载。
- 后续 vLLM/SGLang 启动命令中的模型路径参数一律使用 `/model/<模型名>`，不得继续使用宿主机路径或文档中的旧路径。

### 2.2 环境配置
根据用户提供的测试信息，如果包含“精度测试”则需要配置精度测试环境；如果包含“性能测试”则需要配置性能测试环境。
1. 精度测试环境配置：
- 读取 `references/evaluation_framework/install_evaluation_framework.md`
- 让用户选择评测工具：`evalscope`（默认）或 `opencompass`
- 容器创建后先检查容器内评测环境：
  ```bash
  docker exec <container_name> bash -lc "pip list | grep -E 'evalscope|opencompass|openai'"
  ```
- 若选择 `evalscope`，但 `pip list | grep evalscope` 无结果，必须先安装 `evalscope`，再进入测试。
- 若选择 `opencompass`，但 `pip list | grep -E 'opencompass|openai'` 缺少必要依赖，必须先安装 OpenCompass 和 API 评测依赖。
- 准备测试数据集：默认宿主机路径 `/public/home/wanghy18/opencompass/data`，容器内路径 `/mnt/opencompass/data`；若默认路径不存在，向用户索要路径。
2. 性能测试环境配置：
- 

## 第三步：推理服务与测试

### 3.1 推理服务脚本准备

**启动模型服务必须优先参考 HYGON-AI cookbook 最佳实践：**

在生成或修改 `serve_<模型名>.sh` 之前，先读取 `references/model_deployment_cookbook.md`，并按用户选择的框架和模型族定位外部最佳实践：

- vLLM: `https://github.com/HYGON-AI/dcu-inference-cookbook/tree/main/docs/model-deployment/vllm`
- SGLang: `https://github.com/HYGON-AI/dcu-inference-cookbook/tree/main/docs/model-deployment/sglang`

执行规则：

1. 先确认或推断推理框架：`vllm` 或 `sglang`。
2. 根据模型名匹配模型族文档，例如 `qwen3.md`、`qwen3.5.md`、`deepseek-v3.2.md`、`glm-5.md`、`kimi-k2.5.md`。
3. 从 cookbook 中提取匹配条目的环境变量、启动命令、推荐硬件、卡数、TP/PP/DP、dtype、量化方式、上下文长度、显存比例和特殊优化开关。
4. 将 cookbook 命令适配到当前容器路径和端口约定；无论 vLLM 还是 SGLang，模型路径参数都必须统一为 `/model/<模型名>`。
5. 生成脚本时不得删除 cookbook 中的 DCU、NUMA、通信、量化、MoE、PD/IFB 调度相关环境变量。
6. 默认使用 cookbook 中的 IFB 部署方式进行测试；只有用户明确要求 PD 分离模式时，才选择 PD 相关条目或参数。
7. 匹配 cookbook 条目时必须同时对齐模型、框架、加速卡型号（如 BW1000、BW1100、K100_AI）、卡数和部署方式（IFB/PD）。若当前节点卡型与 cookbook 启动命令对应卡型不一致，不要强行改写命令，直接询问用户是否可以提供适配当前卡型的脚本。
8. 只有当 cookbook 没有覆盖目标模型/框架/卡型/部署方式组合时，才回退到本地 `scripts/serve_*.sh` 模板或请求用户提供脚本。

**vLLM 补充方案来源：**

若 HYGON-AI cookbook 未覆盖目标模型，且用户选择的框架为 `vllm`，再读取 `references/vllm_test_guidance.md`，从 `references/VLLM测试指导.md` 中查找模型测试方案。

本地补充文档中的卡型别名必须规范化：

- `NMZ` / `nmz` -> `BW1100` 或 `BW1101`
- `BMZ` / `bmz` / `BW1000` -> `BW1000`
- `KME` / `K100_AI` / `K100AI` -> `K100AI`

如果 cookbook 和本地补充文档都找不到目标模型/卡型/部署方式，或补充文档对应卡型标记为 `暂无`、`不支持`、`有bug`、`待重新测试`、`预估需要双机`，必须询问用户是否能够提供适配脚本，不要自动编写启动命令。

生成或确认脚本时，必须向用户说明：

- 使用的框架：`vllm` 或 `sglang`
- 引用的 cookbook 文件，或本地补充来源
- 匹配的模型条目
- 推荐硬件和卡数
- 当前节点加速卡型号
- 宿主机模型目录和容器内模型路径 `/model/<模型名>`
- 部署方式：默认 `IFB`，或用户指定的 `PD`
- TP/PP/DP、dtype、量化、上下文长度、端口
- 保留或新增的关键环境变量

---

**读取 `scripts/` 目录，确认是否已有目标模型的启动脚本：**

```bash
ssh -tt <Node_IP> "docker exec <container_name> ls /workspace/scripts/"
```

> 注意：容器创建时已将宿主机 `pwd` 挂载到容器 `/mnt`，`scripts/` 目录挂载后位于容器内 `/mnt/scripts/`。
> 若宿主机 `scripts/` 已同步至容器可访问路径，直接使用；否则先将脚本上传到目标节点。

**已有对应模型脚本：**

优先查找框架感知命名：`serve_<framework>_<模型名>.sh`；兼容旧命名：`serve_<模型名>.sh`。

找到脚本后不要直接启动。必须先按 HYGON-AI cookbook 对应条目做一次轻量校验：

- 框架是否一致（vLLM/SGLang）
- 模型路径是否统一为 `/model/<模型名>`，TP/卡数、dtype、量化参数是否与 cookbook 冲突
- cookbook 条目的加速卡型号和部署方式是否与当前测试环境一致
- 关键 DCU 环境变量和特殊优化开关是否缺失
- 服务端口和日志路径是否明确

若脚本与 cookbook 明显不一致，先向用户展示差异并建议更新脚本；用户确认后再进入 3.2。若主要差异是加速卡型号不匹配，直接询问用户是否能够提供适配当前卡型的启动脚本。

---

**未找到对应模型脚本时，向用户提供两个选项：**

```
scripts/ 目录下未找到 <模型名> 的启动脚本。请选择：

1. 由您提供脚本内容（直接粘贴或提供路径）
2. 由我参考 HYGON-AI cookbook 最佳实践自动生成一个新脚本
```

**选项 1（用户提供）：**
- 用户粘贴脚本内容后，将其保存为 `scripts/serve_<模型名>.sh`
- 按 cookbook 对应条目做轻量校验，向用户确认脚本内容后进入 3.2

**选项 2（自动生成）：**

优先读取 HYGON-AI cookbook 对应文档，提取以下关键结构作为模板基础：
- 环境变量区（DCU、NUMA、通信、量化、MoE、PD/IFB、框架专属优化开关等）
- 启动命令区（vLLM 的 `vllm serve` 或 SGLang 的 `python3 -m sglang.launch_server`）
- 推荐配置区（框架版本、推荐硬件、卡数、TP/PP/DP、dtype、量化方式、上下文长度、显存比例、端口）
- 启动命令元信息（模型条目、加速卡型号、部署方式 IFB/PD、框架版本、推荐卡数）

若 cookbook 未覆盖目标模型/框架组合，再读取 `scripts/` 下现有脚本作为 fallback 模板。

生成规则：
- **环境变量区完整保留**，不得删改 cookbook 和 `references/rules/dcu_adaptation_rules.md` 中的 DCU 底层环境变量。
- 模型路径替换为当前容器内实际路径 `/model/<模型名>`；该路径由容器创建时的只读挂载保证，对 vLLM 和 SGLang 都必须一致。
- TP/PP/DP、dtype、量化、上下文长度、显存比例等以 cookbook 匹配条目为准。
- 默认选择 IFB 部署方式；只有用户明确要求 PD 分离模式时才使用 PD 相关启动命令。
- 生成脚本开头必须写明当前启动命令对应的元信息，包括模型、框架、cookbook 文件、加速卡型号、部署方式、推荐卡数、TP/PP/DP、dtype、量化方式、端口。
- vLLM 默认日志建议为 `/tmp/vllm_serve.log`，SGLang 默认日志建议为 `/tmp/sglang_serve.log`。
- vLLM 默认端口按启动命令或框架默认处理；SGLang 常见端口为 `30000`，若启动命令指定端口则以指定端口为准。
- 若当前节点加速卡型号与 cookbook 条目不一致，停止自动生成并询问用户是否能够提供适配脚本。
- 若 cookbook 中没有目标规模的明确 TP，才根据模型规模、可用卡数、加速卡型号和用户目标进行推断，并向用户说明推断依据。

生成后展示脚本全文，**向用户确认后**保存为 `scripts/serve_<模型名>.sh`，再进入 3.2。

---

### 3.2 推理服务启动与监控

**启动服务：**

将脚本上传至目标节点并在容器内以后台模式运行：

```bash
# 1. 将脚本拷贝到节点（若尚未同步）
scp scripts/serve_<模型名>.sh <Node_IP>:/tmp/serve_<模型名>.sh

# 2. 在容器内后台执行，日志重定向
# vLLM 建议日志：/tmp/vllm_serve.log
# SGLang 建议日志：/tmp/sglang_serve.log
ssh -tt <Node_IP> "docker exec -d <container_name> bash -c \
  'bash /tmp/serve_<模型名>.sh > <日志路径> 2>&1'"
```

告知用户：服务已在后台启动，接下来会启动轻量 watcher 监控服务就绪状态。

---

**高效监控原则（必须遵守，适用于 vLLM / SGLang 服务）：**

- 不要在 Agent 会话中反复读取完整日志，也不要固定 `tail -n 50` 轮询日志正文。
- 在目标节点宿主机启动后台 watcher，由 watcher 持续检查服务状态并写入小型 JSON 状态文件。
- 最终就绪判定以 HTTP 探活为准，默认依次尝试 `/health`、`/v1/models`、`/server_info`、`/get_server_info`，任一端点返回 2xx/3xx 才允许触发测试。
- 日志只用于辅助判断启动进度和失败原因；watcher 每次只扫描新增日志片段，避免重复消费日志。
- Agent 正常情况下只读取 `/tmp/llm_status.json`；只有 `error` 或 `timeout` 时才读取少量日志上下文。

**上传并启动服务监控脚本：**

```bash
# 3. 上传 watcher 到目标节点
scp scripts/watch_llm_ready.sh <Node_IP>:/tmp/watch_llm_ready.sh

# 4a. vLLM 示例（默认端口 8000）
ssh -tt <Node_IP> "nohup bash /tmp/watch_llm_ready.sh \
  <container_name> \
  /tmp/vllm_serve.log \
  /tmp/llm_status.json \
  8000 \
  vllm \
  '/health,/v1/models' \
  > /tmp/watch_llm_ready.monitor.log 2>&1 & echo 监控进程PID: $!"

# 4b. SGLang 示例（按实际启动端口替换，常见为 30000）
ssh -tt <Node_IP> "nohup bash /tmp/watch_llm_ready.sh \
  <container_name> \
  /tmp/sglang_serve.log \
  /tmp/llm_status.json \
  30000 \
  sglang \
  '/health,/v1/models,/server_info,/get_server_info' \
  > /tmp/watch_llm_ready.monitor.log 2>&1 & echo 监控进程PID: $!"
```

告知用户：服务已在后台启动，监控进程已运行。后续将读取状态文件判断是否可以触发测试。

---

**状态查询（低 token 轮询）：**

Agent 侧建议每 **30~60 秒** 查询一次，每次只读取 JSON 状态文件：

```bash
ssh -tt <Node_IP> "cat /tmp/llm_status.json"
```

根据 `status` 字段处理：

| status 值 | 含义 | 操作 |
|-----------|------|------|
| `starting` | 服务仍在加载 | 展示 `message` 和 `last_check`，继续等待 |
| `almost_ready` | 日志显示服务接近就绪，但 HTTP 探活未确认 | 继续等待下一次状态 |
| `ready` | HTTP 探活已通过 | 立即进入测试步骤 |
| `error` | 启动日志中检测到错误 | 展示 `detail`，询问是否排查或重启 |
| `timeout` | 超过 30 分钟仍未就绪 | 展示 `detail` 和建议操作 |

**只有在 `status == "ready"` 时才能触发精度/性能测试。**

---

**失败或超时时再读取少量日志：**

```bash
ssh -tt <Node_IP> "docker exec <container_name> tail -n 80 <日志路径>"
```

不要读取完整日志文件，除非用户明确要求排查完整日志。

---

**ready 状态确认输出：**

当 `/tmp/llm_status.json` 中 `status` 为 `ready` 时，输出以下确认信息：

```
✅ 推理服务已成功启动！

节点：<Node_IP>
容器：<container_name>
模型：<模型名>
服务端口：<端口>
日志路径：<日志路径>
就绪端点：<ready_endpoint>

服务已就绪，可以开始进行测试。
```

---

**监控超时处理：**

watcher 默认等待 **30 分钟**。若 `/tmp/llm_status.json` 中 `status` 为 `timeout`，告知用户：

```
⚠️ 服务启动已超过 30 分钟，未检测到就绪信号。
最近日志摘要如下：
...（status.detail 字段内容）...

建议操作：
1. 查看少量日志上下文：docker exec <container_name> tail -n 80 <日志路径>
2. 检查模型路径是否正确：/model/<模型名>
3. 检查显存是否充足
4. 检查探活端点是否可访问：/health、/v1/models、/server_info、/get_server_info
```

### 3.3 精度测试执行

> 精度测试可能持续数小时乃至 24 小时以上，**不能依赖 Claude 会话保持连接来轮询**。
> 解决方案：在节点宿主机上启动后台监控进程（`watch_accuracy.sh`），它独立运行、定期写状态文件；
> 用户随时回来时，Claude 只需读取状态文件即可获知最新进度，无需会话连续。

---

**Step A：确认测试参数**

向用户确认以下信息（未提供则使用默认值）：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 模型名 | 与推理服务一致 | 上一步所用模型 |
| 评测工具 | `evalscope` 或 `opencompass` | `evalscope` |
| 数据集 | 评测工具支持的数据集名或 OpenCompass 配置中的数据集 | `gsm8k` |
| limit | 测试条数，`0` 表示全量 | `10`（调试），正式测试去掉此参数 |
| API 端口 | 推理服务端口 | 计划表或启动脚本端口 |
| 数据集宿主机路径 | 目标节点上的数据集根目录 | `/public/home/wanghy18/opencompass/data` |
| OpenCompass 配置 | 使用 opencompass 时需要的 config 或参数 | 用户提供或现场确认 |

---

**Step A.1：确认本地数据集规则**

默认数据集路径：

- 宿主机：`/public/home/wanghy18/opencompass/data`
- 容器内：`/mnt/opencompass/data`

若目标节点上不存在默认宿主机路径，先向用户索要路径，并在创建容器时挂载为 `/mnt/opencompass/data:ro`。

evalscope 本地数据集必须使用以下特殊规则：

- `gsm8k`：避免 `BuilderConfig 'main' not found. Available: ['default']`，使用：
  ```json
  {"gsm8k": {"local_path": "/mnt/opencompass/data/gsm8k", "subset_list": ["default"]}}
  ```
- `humaneval`：不要使用 `openai_humaneval` 作为本地 subset；使用：
  ```json
  {"humaneval": {"local_path": "/mnt/opencompass/data/humaneval", "subset_list": ["default"]}}
  ```
- `math_500`：本地目录名按实测为 `math`，默认文件为 `/mnt/opencompass/data/math/test.jsonl`。不要通过直接截取 JSONL 前 N 行来构造小样本；使用 `limit` 控制样本数。若出现 `KeyError: 'answer'`，先检查 `test.jsonl` 是否保留 `answer` 字段，再决定是否需要用户提供修正后的数据文件。

**Step A.2：多模型多数据集调度原则**

当同时测试多个模型和多个数据集时，不要把“同一个数据集所有模型全部完成”作为进入下一个数据集的全局屏障。

正确行为：

- 每个模型维护自己的数据集队列，例如 `gsm8k -> math_500 -> humaneval`。
- 某个模型完成当前数据集后，只要该模型服务仍健康、端口可用、容器未释放，就立即进入该模型的下一个数据集。
- 其他模型仍在当前数据集末尾时，不阻塞已完成模型继续测试。
- 某个模型完成全部数据集后，再根据计划释放加速卡资源或保留服务等待用户确认。
- 报告按 `<模型, 数据集>` 粒度增量记录，最终再汇总总表。

---

**Step B：按评测工具准备脚本**

如果用户选择 `evalscope`，上传脚本到节点：

```bash
scp scripts/eval_accuracy.sh <Node_IP>:/tmp/eval_accuracy.sh
scp scripts/watch_accuracy.sh <Node_IP>:/tmp/watch_accuracy.sh
```

如果用户选择 `opencompass`：

- 不使用 `eval_accuracy.sh`。
- 先确认 OpenCompass 配置、数据集路径、模型 API 地址和输出目录。
- 仍上传 `watch_accuracy.sh` 用于监控日志状态。

```bash
scp scripts/watch_accuracy.sh <Node_IP>:/tmp/watch_accuracy.sh
```

---

**Step C：在容器内后台启动精度测试**

`evalscope` 执行方式：

```bash
ssh -tt <Node_IP> "docker exec -d <container_name> bash -c \
  'bash /tmp/eval_accuracy.sh <模型名> <数据集> <limit> \
   <端口> \
   > /tmp/eval_accuracy.log 2>&1'"
```

`opencompass` 执行方式：

根据用户提供或确认的 OpenCompass 配置启动。以下为模板，实际命令必须按当前 OpenCompass 配置调整：

```bash
ssh -tt <Node_IP> "docker exec -d <container_name> bash -c \
  'cd /workspace/opencompass || cd /mnt/opencompass || cd /workspace && \
   python -m opencompass <OpenCompass配置或参数> \
   > /tmp/eval_accuracy.log 2>&1'"
```

---

**Step D：在宿主机上启动后台监控进程**

监控脚本运行在**宿主机**（不是容器内），通过 `nohup` 挂后台，读取评测日志并写状态文件。不要固定时间读取模型服务日志；evalscope/opencompass 的测试进度优先从 `/tmp/eval_accuracy.log` 和 prediction 文件判断。

若 evalscope 已生成 prediction 文件或输出目录，将其路径作为第三个参数传入；若暂不确定，传 `auto`，watcher 会在容器内搜索近期 prediction/jsonl/json 文件并在首次出现 3 条样本后做一次乱码检测。

```bash
ssh -tt <Node_IP> "nohup bash /tmp/watch_accuracy.sh \
  /tmp/eval_accuracy.log \
  /tmp/eval_status.json \
  auto \
  <container_name> \
  120 \
  > /tmp/watch_accuracy.monitor.log 2>&1 & echo 监控进程PID: $!"
```

告知用户：

```
✅ 精度测试已在后台启动，监控进程已运行。

节点：<Node_IP>
容器：<container_name>
模型：<模型名>
数据集：<数据集>
测试日志：/tmp/eval_accuracy.log（容器内）
状态文件：/tmp/eval_status.json（宿主机）

⏳ 测试可能持续数小时，您可以随时回来查询进度。
   下次回来时，告诉我"查看精度测试进度"即可。
```

---

**Step E：用户随时查询进度（按需触发）**

当用户说"查看进度"、"测试跑完了吗"时，执行：

```bash
# 读取状态文件
ssh -tt <Node_IP> "cat /tmp/eval_status.json"

# 取最新日志末尾
ssh -tt <Node_IP> "docker exec <container_name> tail -n 30 /tmp/eval_accuracy.log"
```

根据状态文件中的 `status` 字段响应：

| status 值 | 含义 | 操作 |
|-----------|------|------|
| `running` | 仍在测试 | 展示 `progress` 字段内容，告知用户继续等待 |
| `done` | 测试完成 | 进入 3.4 收集完整结果 |
| `error` | 出现错误 | 展示 `result` 字段的报错内容，询问用户是否重试 |
| `aborted` | prediction 连续 3 条疑似乱码 | 当前评测/服务已被中断以释放加速卡资源，容器保留；展示 `result` 并反馈用户 |

---

### 3.4 日志收集与精度结果提取

测试完成后（状态文件 `status == "done"`），执行完整日志收集：

```bash
ssh -tt <Node_IP> "docker exec <container_name> cat /tmp/eval_accuracy.log"
```

从日志中提取：
- 各数据集的精度数值（accuracy、pass@k 等）
- 测试耗时（日志首末时间戳相减）
- 评测样本数量
- 任何警告或跳过信息

---

## 第四步：精度报告生成

若用户需要正式报告或报告格式，读取 `references/accuracy_report_template.md`。普通进度查询或单项结果反馈时，只需按 `<模型, 数据集>` 粒度汇总关键结果。
