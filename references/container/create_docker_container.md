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

注意：

- `:ro` 必须保留，模型目录以只读方式挂载。
- 精度数据集目录也必须以只读方式挂载。
- 若本次任务不包含精度测试，可省略数据集挂载项。
- vLLM 和 SGLang 启动命令中的模型路径都统一使用 `/model/<MODEL_NAME>`。
- 不要把用户提供的宿主机路径直接写入服务启动命令。

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
  -v <workdir_on_node>:/mnt \
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

测试完成后默认停止容器释放 DCU 资源，但不删除容器，便于复查环境：

```bash
ssh -tt <Node_IP> "docker stop <container_name>"
```

只有用户明确要求删除容器时再执行：

```bash
ssh -tt <Node_IP> "docker stop <container_name> && docker rm <container_name>"
```
