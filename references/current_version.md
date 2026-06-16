# 当前版本说明

当前版本：`v0.7.2-watch-queue-cleanup`

仅当用户询问 skill 当前能力、边界、版本变化，或维护 skill 时读取本文件。普通推理/测试任务不需要加载。

## 当前版本特性

- 已备份旧版本到 `/public/home/wanghy18/skill_backups/dcu-llmtest-pipeline-20260608-115609`。
- 移除旧模型服务监控和后台编排脚本；当前使用一次性 `scripts/watch_model_once.sh` 做会话内观察。
- 当前执行路径不再生成旧 JSON 状态文件、旧事件流水或旧后台日志；精度阶段 one-shot watch 默认每 20 分钟调用一次。
- 唯一测试报告为 `reports/test_report.md`；`reports/task_plan.md` 可继续作为人工计划表，表头包含 `加速卡信息` 和 `所需卡数`。
- 不再生成重复摘要报告。
- 保留 OpenCompass 固定启动脚本 `scripts/start_opencompass_safe.sh`，继续强制区分宿主机 `RUN_DIR` 与容器内 `CONFIG/WORK_DIR`，避免路径混用和权限问题；遇到类似 OpenCompass config/import/plugin 启动问题时允许通过 `autotest/configs` 软链接和 `VLLM_PLUGINS="" python /workspace/opencompass/run.py <config>.py --debug` 兜底启动。
- 保留 HYGON-AI cookbook-first 的服务脚本生成规则：只允许适配 `HIP_VISIBLE_DEVICES`、容器模型路径和服务监听端口。
- 保留多模型计划表规则：同节点空闲卡足够时必须并发分配不同 `cards`/`port`；目标模式下某任务完成或异常后立即释放资源，只有加速卡型号和卡数匹配时才扫描待测试任务补充调度；所有任务终态后删除本轮测试容器。

## 当前版本边界

- 暂不提供后台跨会话模型服务监控。
- 暂不提供旧 JSON 状态恢复。
- 模型服务 ready 判断和 OpenCompass 进度观察只在当前会话内通过 one-shot watch 推进。
- 性能测试流程仍处于占位阶段，尚未提供标准压测脚本和吞吐/延迟指标汇总。
- 自动报告到聊天依赖当前 Agent 会话仍可执行工具；当前版本不能在会话结束或运行环境回收后主动唤醒 Agent。
