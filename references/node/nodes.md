# DCU Megatron 架构适配与规则知识库 
**【第一指令】本文件供 AI Agent 自动读取使用。在调用dcu-llmtest-pipeline skill需要进行模型推理查找当前可用节点信息**

## 0. 当前可用节点ip列表
### 0.1 NMZ
10.16.1.4
10.16.1.7
### 0.2 BMZ
10.16.1.1
10.16.1.41
10.16.1.42
10.16.1.44
### 0.3 K100AI
10.16.1.82
10.16.1.83
10.16.1.84
10.16.1.85
## 1. 查找空闲节点并返回信息
通过` ssh 节点ip "执行的命令" `来向目标节点发送命令

### 1.1 节点命令
查看当前节点占用情况:`/opt/hyhal/bin/hy-smi`
查看当前节点频率情况:`/opt/hyhal/bin/hy-smi -c`
查看当前驱动版本:`/opt/hyhal/bin/hy-smi --showdriverversion`
查看当前节点加速卡型号:`/opt/hyhal/bin/hy-smi --showproductname`

