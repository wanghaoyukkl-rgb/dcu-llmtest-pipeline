---
NOTE: 在 DCU 和 NVIDIA 平台创建容器需使用不同的命令。为了适配 Agent 自动化执行，必须使用 -dit 参数。
---
# 自动化容器部署指南

### 1. 镜像检索规范
在执行创建前，必须先在目标节点确认镜像：
`ssh -tt <Node_IP> "docker images | grep vllm"`

若用户指定镜像：检查是否存在，不存在则终止任务。

若用户未指定：选取最新的镜像 ID 填入下方的 Container_image_ID。

获取当前日期
```shell
date +"%Y-%m-%d-%H-%M"
```
container-name=当前日期+模型名

在**DCU** 平台创建容器，不适用 N 卡。

```shell
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
-v `pwd`:/mnt -v  /module:/module:ro -v /public/opendas/DL_DATA/llm-models/:/model/:ro \
  <Container_image_ID> \
  bash"
```

# 自动化测试执行规范
容器创建成功后，Agent 严禁尝试通过交互式方式进入容器。必须使用 docker exec 进行指令透传。

执行测例：
ssh -tt <Node_IP> "docker exec <container_name> bash /workspace/test.sh"

查看日志：
ssh -tt <Node_IP> "docker logs <container_name>"

# 任务闭环与清理
测试完成后，Agent 应询问用户是否清理环境。若需清理：
ssh -tt <Node_IP> "docker stop <container_name> && docker rm <container_name>"