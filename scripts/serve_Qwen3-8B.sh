#!/bin/bash
# 模型：Qwen3-8B
# tensor-parallel-size：1（单卡）
# 适用平台：DCU（HIP/ROCm）

export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3

vllm serve /model/qwen3/Qwen3-8B \
        --dtype float16 \
        --trust-remote-code \
        --tensor-parallel-size 1 \
        --disable-cascade-attn
