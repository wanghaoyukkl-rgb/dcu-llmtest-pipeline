---
NOTE: 在 DCU 和 NVIDIA 平台创建容器需使用不同命令。本 skill 当前面向 DCU 推理测试，容器必须使用 `docker run -itd` 后台创建。
---

# 自动化容器部署指南

## 1. 创建前必须收集的信息

在执行容器创建前，必须先确认以下字段：

- `Node_IP`：目标节点 IP。
- `Container_image_ID`：用户指定或在目标节点上选择的镜像 ID/名称。
- `ACCELERATOR`：当前测试加速卡型号，例如 `BW1100`、`BW1000`、`K100AI`。
- `MODEL_NAME`：当前测试模型名，用于容器路径 `/model/<MODEL_NAME>`。
- `FRAMEWORK`：`vllm` 或 `sglang`。
- `HOST_MODEL_PATH`：用户提供的目标节点宿主机模型目录。
- `HOST_DATASET_PATH`：精度测试所需数据集根目录，默认 `/public/home/wanghy18/opencompass/data`。
- `RUN_DIR`：本次测试落盘目录，用于挂载脚本、报告、服务日志和 OpenCompass 输出。
- `OPENCOMPASS_SOURCE`：OpenCompass 来源；默认 `container-installed`，表示在容器内 `/workspace/opencompass` 拉取并安装。仅当用户明确指定本地现有工程路径时，才使用 `host-mounted:<path>` 并挂载到 `/workspace/opencompass`。

若用户未提供 `HOST_MODEL_PATH`，不要猜测模型目录，先询问用户提供具体路径。

若任务包含精度测试，先在目标节点检查默认数据集目录：

```bash
ssh -tt <Node_IP> "test -d /public/home/wanghy18/opencompass/data && echo FOUND || echo MISSING"
```

若默认目录不存在，向用户索要数据集根目录；不要自动下载或创建大数据集。

## 2. 镜像检索规范

在执行创建前，必须先在目标节点确认镜像：

```bash
ssh -tt <Node_IP> "docker images | grep -E 'vllm|sglang|dcu|llm'"
```

若用户指定镜像：检查是否存在，不存在则终止任务并向用户说明。

若用户未指定：选取最新且与目标框架匹配的镜像 ID 填入 `<Container_image_ID>`，并向用户说明选择依据。

## 3. 命名与挂载规范

获取当前日期：

```bash
date +"%Y%m%d"
```

容器名必须使用：

```text
<ACCELERATOR>-<YYYYMMDD>-<MODEL_NAME>-<FRAMEWORK>
```

若 `MODEL_NAME` 包含 `/` 或空格，容器名中替换为 `-`；容器内模型路径仍使用 `/model/<MODEL_NAME>`。

模型目录挂载规则：

```text
-v <HOST_MODEL_PATH>:/model/<MODEL_NAME>:ro
```

精度测试数据集挂载规则：

```text
-v <HOST_DATASET_PATH>:/mnt/opencompass/data:ro
```

本次测试目录挂载规则：

```text
-v <RUN_DIR>:/mnt/dcu-llmtest-run
```

服务日志必须写入：

```text
宿主机: <RUN_DIR>/serve_logs/<TASK_ID>.serve.log
容器内: /mnt/dcu-llmtest-run/serve_logs/<TASK_ID>.serve.log
```

OpenCompass 输出必须写入：

```text
宿主机: <RUN_DIR>/<TASK_ID>/opencompass
容器内: /mnt/dcu-llmtest-run/<TASK_ID>/opencompass
```

注意：

- `:ro` 必须保留，模型目录以只读方式挂载。
- 精度数据集目录也必须以只读方式挂载。
- 若本次任务不包含精度测试，可省略数据集挂载项。
- `/mnt/opencompass/data` 只用于数据集；不要将 OpenCompass 工程挂载到 `/mnt/opencompass`。
- 除非用户明确指定使用本地现有 OpenCompass 工程，否则容器创建阶段不挂载宿主机 OpenCompass 工程，后续按安装流程在容器内 `/workspace/opencompass` 拉取和安装。
- 如果用户明确指定本地现有 OpenCompass 工程，挂载规则为 `-v <HOST_OPENCOMPASS_PATH>:/workspace/opencompass:ro` 或按用户要求读写挂载，并在计划表/报告中记录来源 `host-mounted:<path>`。
- vLLM 和 SGLang 启动命令中的模型路径都统一使用 `/model/<MODEL_NAME>`。
- 不要把用户提供的宿主机路径直接写入服务启动命令。
- 启动服务前必须 `mkdir -p <RUN_DIR>/serve_logs`，并将服务 stdout/stderr 重定向到该目录下的 `<TASK_ID>.serve.log`。报告和排查时优先使用宿主机路径，容器内对应路径为 `/mnt/dcu-llmtest-run/serve_logs/<TASK_ID>.serve.log`。
- OpenCompass 进度观察只读取 `<RUN_DIR>/<TASK_ID>/opencompass/logs/infer`、`logs/eval` 和可选 `summary`。

## 4. DCU 容器创建命令

在**DCU** 平台创建容器，不适用 N 卡。必须使用 `docker run -itd`，不得使用 `docker run -it`。

```bash
ssh -tt <Node_IP> "docker run -itd --name <container-name> \
  --privileged \
  --shm-size=512G \
  --device=/dev/kfd --device=/dev/dri/ \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  --ulimit stack=-1:-1 \
  --ulimit memlock=-1:-1 \
  --ipc=host \
  --network host \
  --group-add video \
  -v /opt/hyhal:/opt/hyhal:ro \
  -v <RUN_DIR>:/mnt/dcu-llmtest-run \
  -v <HOST_MODEL_PATH>:/model/<MODEL_NAME>:ro \
  -v <HOST_DATASET_PATH>:/mnt/opencompass/data:ro \
  <Container_image_ID> \
  bash"
```

创建后必须向用户回传：

- 容器名
- 节点 IP
- 镜像 ID/名称
- 宿主机模型目录
- 容器内模型路径：`/model/<MODEL_NAME>`
- 宿主机数据集目录：精度测试时必填，默认 `/public/home/wanghy18/opencompass/data`
- 容器内数据集路径：`/mnt/opencompass/data`
- OpenCompass 来源：默认 `container-installed`；若用户指定本地工程，则记录 `host-mounted:<path>` 和容器内路径 `/workspace/opencompass`
- 服务日志目录：`<RUN_DIR>/serve_logs`
- 框架：`vllm` 或 `sglang`
- 加速卡型号

# 自动化测试执行规范

容器创建成功后，Agent 严禁尝试通过交互式方式进入容器。必须使用 `docker exec` 进行指令透传。

执行测例：

```bash
ssh -tt <Node_IP> "docker exec <container_name> bash /workspace/test.sh"
```

查看日志：

```bash
ssh -tt <Node_IP> "docker logs <container_name>"
```

# 任务闭环与清理

单个任务完成或异常后，默认先停止容器释放 DCU 资源；多模型目标模式随后立即扫描计划表中的 `待测试` 任务，只有加速卡型号和卡数匹配时才启动下一项：

```bash
ssh -tt <Node_IP> "docker stop <container_name>"
```

所有任务均进入 `通过` 或 `异常` 后，删除本轮 skill 管理的测试容器：

```bash
ssh -tt <Node_IP> "docker stop <container_name> && docker rm <container_name>"
```
