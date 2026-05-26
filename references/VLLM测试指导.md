VLLM测试指导

（1）模型为二级标题；测试模式为三级标题；加速卡为四级标题；

（2）本文已隐去人员标记，仅保留模型测试方案信息；

（3）模型名称需要与社区命名一致；如果是量化模型需要明确是社区量化还是内部量化；

（4）如果不同加速卡有测试区别，需要在不同加速卡下明确，相同部分全部放在加速卡上统一编写；

（5）总结出来测试方法，不明确具体镜像；

（6）注意编写格式，如使用代码块，编写整洁；

# 导航

**导航**
- Kimi-K2.5-w4a16(官方模型)
- Qwen3-30B-A3B
- Qwen3-8B
- Qwen3-8B.w8a8（非社区量化）
- Qwen3-30B-A3B.w8a8(社区量化)
- Qwen3-VL-235B-A22B-Thinking
- DeepSeek-V3.2-Channel-INT8（非社区量化）
- DeepSeek-V3.2-channel-fp8（非社区量化）
- Qwen3-235B-A22B
- Qwen3-235B-A22B-W8A8（非社区量化）
- Qwen3-235B-A22B-Instruct-2507
- Qwen3-32B-W8A8（社区量化）
- MiniMax-M2.5-W8A8(社区量化)
- MiniMax-M2_5-Channel-FP8-w8a8(内部量化)
- MiniMax-M2.5-bf16
- Qwen3-32B
- Qwen2.5-VL-72B-Instruct
- Qwen2.5-VL-72B-Instruct-quantized.w8a8（社区量化）
- GLM-5-w4a8-V2_6_test（非社区量化）
- GLM-5-W8A8（社区量化）
- GLM5-Channelwise-FP8-quantized（社区量化）
- DeepSeek-R1-Distill-Llama-70B
- DeepSeek-R1-Distill-Qwen-32B
- GLM4.7-w8a8
- GLM5.1-Channel-INT8
- GLM5.1-Channel-FP8
- Qwen3-VL-30B-A3B-Thinking
- DeepSeek-R1-Channel-INT8
- DeepSeek-R1-Channe-FP8
- Qwen3-VL-235B-A22B-Instruct
- Qwen3-Coder-480B-A35B-Instruct-w8a8
- Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic
- DeepSeek-R1-0528-W4A8-V2
- Qwen3-4B-Thinking-2507
- QwQ-32B
- DeepSeek-R1-bf16
- Qwen3-Next-80B-A3B-Instruct
- Qwen3-0.6B/Qwen3-4B
- Qwen3.5-122B-A10B
- GLM-4-32B-0414
- DeepSeek-V3.1-Terminus-fp8
- DeepSeek-R1-Distill-Llama-70B-quantized.w8a8
- Qwen3.5-35B-A3B & Qwen3.5-35B-A3B-W8A8
- DeepSeek-V3-W4A8-V2
- Qwen3-VL-32B-Instruct
- Qwen2.5-VL-32B-Instruct
- Qwen3-VL-4B-Instruct

## Kimi-K2.5-w4a16(官方模型)

### 测试模式

```bash
rm -rf ~/.cache
rm -rf ~/.triton
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export VLLM_USE_LIGHTOP=1
export VLLM_USE_PIECEWISE=1
export VLLM_1D_MROPE=1
export USE_FUSED_RMS_QUANT=0 
export VLLM_USE_LIGHTOP_FUSED_TOPP_TOPK=1
export VLLM_W8A8_BACKEND=3
export VLLM_USE_FLASH_ATTN_FP8=1
export VLLM_USE_CAT_MLA=1 
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 
export VLLM_ROCM_USE_AITER_MOE=1

vllm serve /module/Kimi-K2.5 \
    --trust-remote-code   \
    --dtype bfloat16  \
    --max-model-len 65536  \
    --disable-log-requests  \
    --enable-prefix-caching \
    --gpu-memory-utilization 0.90 \
    --max-num-batched-tokens 16384 \
```

#### BW1000

```bash
export VLLM_HOST_IP=$(hostname -I | awk '{print $2}')
echo "[INFO] VLLM_HOST_IP=${VLLM_HOST_IP}"
echo $VLLM_HOST_IP
export GLOO_SOCKET_IFNAME=ens61f0np0
export NCCL_SOCKET_IFNAME=ens61f0np0
export VLLM_NUMA_BIND=1
export NCCL_IB_HCA=mlx5_0:1,mlx5_1:1,mlx5_2:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,mlx5_6:1,mlx5_8:1,mlx5_9:1
export HSA_FORCE_FINE_GRAIN_PCIE=1

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_V1=1

--kv-cache-dtype fp8_e5m2 \
-pp 2 -tp8 \
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3 \
-tp 8 \
```

#### K100_AI

```bash
export VLLM_HOST_IP=$(hostname -I | awk '{print $2}')
echo "[INFO] VLLM_HOST_IP=${VLLM_HOST_IP}"
echo $VLLM_HOST_IP
export GLOO_SOCKET_IFNAME=ens61f0np0
export NCCL_SOCKET_IFNAME=ens61f0np0
export VLLM_NUMA_BIND=1
export NCCL_IB_HCA=mlx5_0:1
export HSA_FORCE_FINE_GRAIN_PCIE=1

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_V1=1

-pp 2 -tp8 \
```

## Qwen3-30B-A3B

### 测试模式

```bash
export VLLM_USE_PD_SPLIT=0
export VLLM_USE_PICEWISE=0

vllm serve Qwen/Qwen3-30B-A3B  \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}'
```

#### BW1000

```bash
-tp 2
```

#### NMZ

```bash
-tp 1
```

#### K100_AI

```text
-tp 2
```

## Qwen3-8B

### 测试模式

```bash
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PICEWISE=1

vllm serve Qwen/Qwen3-8B  \
    -tp 1 \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}'
```

#### BW1000

```bash
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3
```

#### K100_AI

暂无

## Qwen3-8B.w8a8（非社区量化）

### 测试模式

```bash
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PICEWISE=1

vllm serve Qwen/Qwen3-8B.w8a8  \
    -tp 1 \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}'
```

#### BW1000

```bash
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3
```

#### K100_AI

暂无

## Qwen3-30B-A3B.w8a8(社区量化)

### 测试模式

```bash
export VLLM_USE_PD_SPLIT=0
export VLLM_USE_PICEWISE=0

vllm serve Qwen/Qwen3-30B-A3B.w8a8  \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}'
```

#### BW1000

```bash
-tp 2
```

#### NMZ

```bash
-tp 1
```

#### K100_AI

```text
-tp 2
```

## Qwen3-VL-235B-A22B-Thinking

### 测试模式

```bash
export VLLM_HOST_IP=12.12.12.74
export NCCL_SOCKET_IFNAME=ib0
export GLOO_SOCKET_IFNAME=ib0
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_IB_HCA=mlx5_0:1,mlx5_2:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,,mlx5_6:1,mlx5_7:1,mlx5_8:1,mlx5_9:1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000

vllm serve /model/Qwen3-VL-235BB-A22B-Thinking \
        --dtype float16 \
        --disable-cascade-attn \
        --distributed-executor-backend ray \
        --tensor-parallel-size 16
```

#### BW1000

```bash
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0 #根据实际情况绑定
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3

vllm serve /model/Qwen3-VL-235BB-A22B-Thinking  \
        --dtype float16 \
        --disable-cascade-attn \
        --tensor-parallel-size 8
```

#### K100_AI

暂无

## DeepSeek-V3.2-Channel-INT8（非社区量化）

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 
export ALLREDUCE_STREAM_WITH_COMPUTE=1           
export NCCL_MIN_NCHANNELS=16                      
export NCCL_MAX_NCHANNELS=16                   
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1   
export VLLM_RPC_TIMEOUT=1800000   
export VLLM_USE_GLOBAL_CACHE13=1
export VLLM_FUSED_MOE_CHUNK_SIZE=16384
export VLLM_REJECT_SAMPLE_OPT=0 
export USE_FUSED_RMS_QUANT=1
export USE_FUSED_SILU_MUL_QUANT=1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 
export VLLM_DISABLE_DSA=0
export VLLM_USE_V32_ENCODE=1
export VLLM_USE_FLASH_MLA=1
export VLLM_USE_FLASH_ATTN_FP8=1
export VLLM_USE_CAT_MLA=1
```

#修复
export VLLM_USE_AITER_MOE_W8A8=0

odel_path=/model/vllm-w8a8-models/DeepSeek-V3.2-Channel-INT8
model=${model_path##*/}
data_type="bfloat16"
tp=8
port=8832
gpu_memory=0.92

vllm serve ${model_path} \
 --trust-remote-code \
 --dtype $data_type \
 --tensor-parallel-size $tp \
 --gpu-memory-utilization $gpu_memory \
 --host 0.0.0.0 \
 --port $port \
 --max-model-len 40960 \
 --disable-log-requests \
 --max-num-batched-tokens 16384 \
 --kv-cache-dtype fp8_ds_mla \
 --enable-chunked-prefill \
 --no-enable-prefix-caching \
 -cc '{"pass_config": {"fuse_act_quant": false}}' \
 --speculative_config '{"method": "mtp", "num_speculative_tokens": 2}'

### BW1000

```text
tp=16

--distributed-executor-backend ray \
```

### NMZ

暂无

### K100_AI

不支持

## DeepSeek-V3.2-channel-fp8（非社区量化）

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7     
export ALLREDUCE_STREAM_WITH_COMPUTE=1           
export NCCL_MIN_NCHANNELS=16                      
export NCCL_MAX_NCHANNELS=16                   
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1   
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PIECEWISE=1 
export USE_FUSED_SILU_MUL_QUANT=1
export VLLM_USE_GLOBAL_CACHE13=1
export VLLM_FUSED_MOE_CHUNK_SIZE=16384
export VLLM_CUSTOM_CACHE=1 
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0
export VLLM_USE_V32_ENCODE=1
export VLLM_USE_FLASH_MLA=1
export VLLM_DISABLE_DSA=0
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1
export VLLM_ZERO_OVERHEAD=1
export VLLM_ZERO_NO_THREAD=1
export VLLM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1
export VLLM_USE_OPT_OP=1
export VLLM_REJECT_SAMPLE_OPT=0 
export VLLM_USE_AITER_MOE_W8A8=0

model_path=/model/deepseek-v3.2/DeepSeek-V3.2-channel-fp8

model=${model_path##*/}
data_type="bfloat16"
tp=8
port=8832
gpu_memory=0.92

vllm serve ${model_path} \
 --trust-remote-code \
 --dtype $data_type \
 --tensor-parallel-size $tp \
 --gpu-memory-utilization $gpu_memory \
 --host 0.0.0.0 \
 --port $port \
 --max-model-len 65536 \
 --max-num-batched-tokens 16384 \
 -q slimquant_marlin \
 --disable-log-requests \
 --disable-custom-all-reduce \
 --no-enable-prefix-caching \
 --block-size 64 \
 --kv-cache-dtype fp8_ds_mla \
 -cc '{"pass_config": {"fuse_act_quant": false}}' \
 --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_marlin"}'
```

### BW1000

不支持

### NMZ

暂无

### K100_AI

不支持

## Qwen3-235B-A22B

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export VLLM_NUMA_BIND=1
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000
export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0
export VLLM_USE_OPT_ZEROS=1

model_path=/model/qwen3/Qwen3-235B-A22B
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="float16"
tp=8
port=8816
gpu_memory=0.95

log_date=$(date "+%Y-%m-%d")
log_dir="xxx_${model}/${log_date}"
mkdir -p "${log_dir}"

vllm serve ${model_path} \
 --dtype ${data_type} \
 --host 0.0.0.0 \
 --port ${port} \
 --trust-remote-code \
 -tp ${tp} \
 --gpu-memory-utilization $gpu_memory \
 --disable-cascade-attn
```

#### BW1000

```bash
```

#根据实际节点情况而定
export VLLM_RANK0_NUMA=3
export VLLM_RANK1_NUMA=1
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=7
export VLLM_RANK5_NUMA=5
export VLLM_RANK6_NUMA=5
export VLLM_RANK7_NUMA=4

--kv-cache-dtype fp8_e5m2

#### NMZ

```bash
```

#根据实际节点情况而定
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3

gpu_memory=0.9
--kv-cache-dtype fp8_e4m3

#### K100_AI

不支持

## Qwen3-235B-A22B-W8A8（非社区量化）

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1           
export NCCL_MIN_NCHANNELS=16                      
export NCCL_MAX_NCHANNELS=16                   
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1   
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PIECEWISE=0 
export VLLM_REJECT_SAMPLE_OPT=1 
export USE_FUSED_SILU_MUL_QUANT=1 
export VLLM_USE_GLOBAL_CACHE13=1 
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 
export VLLM_CUSTOM_CACHE=1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0 
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 
export VLLM_USE_V32_ENCODE=1
export VLLM_USE_FLASH_MLA=1
export VLLM_DISABLE_DSA=0
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1
export VLLM_USE_AITER_MOE_W8A8=0
export VLLM_W8A8_BACKEND=3

export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0
export NCCL_IB_HCA=mlx5_0:1,mlx5_2:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,mlx5_6:1,mlx5_7:1,mlx5_8:1,mlx5_9:1
export ROCSHMEM_HEAP_SIZE=4000000000
export USE_SPE_MQP=1
export ROCSHMEM_SQ_SIZE=1024
export ROCSHMEM_GDA_NUM_QPS_DEFAULT_CTX=256

model_path=/model/vllm-w8a8-models/Qwen3-235B-A22B-W8A8
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
tp=8
port=8878
gpu_memory=0.9

vllm serve ${model_path} \
 --dtype ${data_type} \
 --host 0.0.0.0 \
 --port ${port} \
 --trust-remote-code \
 -tp ${tp} \
 --max-model-len 40960 \
 --disable-log-requests \
 --gpu-memory-utilization $gpu_memory \
 --enable-chunked-prefill \
 --max-num-batched-tokens 16384 \
 --no-enable-prefix-caching \
 -cc '{"pass_config": {"fuse_act_quant": false}, "inductor_compile_config": {"combo_kernels": false}}'
```

#### BW1000

```bash
```

#根据实际节点情况而定
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3

--kv-cache-dtype fp8_e5m2 \

#### NMZ

```bash
```

#根据实际节点情况而定
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3

--kv-cache-dtype fp8_e4m3 \

#### K100_AI

不支持

## Qwen3-235B-A22B-Instruct-2507

### 测试模式

```bash
export VLLM_RANK0_NUMA=0  #按照实际的export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=3
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3


vllm serve /Qwen/Qwen3-235B-A22B-Instruct-2507 \
    --dtype float16 \
    --trust-remote-code \
    -tp 8 \
    --disable-cascade-attn
```

#### BW1000

```text
    --gpu-memory-utilization 0.95 
    --max-model-len 40960
```

#### NMZ

```bash
同测试模式
```

#### K100_AI

```text
有bug，待重新测试
```

## Qwen3-32B-W8A8（社区量化）

### 测试模式

```bash
rm -rf ~/.cache/
rm -rf ~/.triton/
export HIP_VISIBLE_DEVICES=5
export VLLM_USE_LIGHTOP=1
export LMSLIM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1
export VLLM_USE_OPT_RESHAPE_AND_CACHE=1
export VLLM_USE_GLOBAL_CACHE13=1
export VLLM_FUSED_MOE_CHUNK_SIZE=16384
export VLLM_USE_PIECEWISE=1
export VLLM_USE_LIGHTOP_FUSED_TOPP_TOPK=1

model_path=/mnt/model/vllm-w8a8-models/Qwen3-32B.w8a8
model=${model_path##*/}
tp=1
time=$(date "+%m%d-%H%M")
```

#mode="eager"
mode="cudagraph"
logpath="./logs-server"
data_type="fp16"
port=8256
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

vllm serve $model_path \
    -tp $tp \
    --port $port \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --kv-cache-dtype fp8_e5m2 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}' \
    2>&1 | tee  ${logpath}/${model}_$time.log

#### BW1000

```text
--kv-cache-dtype fp8_e5m2 \
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3
```

#### K100_AI

不需要--kv-cache-dtype 参数

## MiniMax-M2.5-W8A8(社区量化)

### 测试模式

```bash
rm -rf ~/.cache
rm -rf ~/.triton
rm -rf /tmp/torchinductor_root/
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=1
export VLLM_RANK5_NUMA=1
export VLLM_RANK6_NUMA=1
export VLLM_RANK7_NUMA=1
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000
export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0
export VLLM_USE_OPT_ZEROS=1
export VLLM_USE_PD_SPLIT=1
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=1
export VLLM_USE_LIGHTOP=1
export LMSLIM_USE_LIGHTOP=1
export USE_FUSED_SILU_MUL_QUANT=1
export USE_FUSED_RMS_QUANT=1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1 #moe_sum融合
```

# 替换lightop接口
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1
export VLLM_USE_OPT_RESHAPE_AND_CACHE=1
# chunksize设置为16384
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化
export VLLM_FUSED_MOE_CHUNK_SIZE=16384  # --max-num-batched-tokens 16384
export VLLM_USE_PIECEWISE=1
export VLLM_USE_LIGHTOP_FUSED_TOPP_TOPK=1
export VLLM_USE_OPT_OP=1 #新加变量
export VLLM_MLA_CP=1
export VLLM_MLA_CPLB=1
model_path=/mnt/model/MiniMax-M2.5-W8A8
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
port=7888
gpu_memory=0.95
bwtype="nmz1100"
# bwtype="bw1000"
log_date=$(date "+%Y-%m-%d")
log_dir="${bwtype}_${model}/${log_date}"
mkdir -p "${log_dir}"
export VLLM_USE_AITER_MOE_W8A8=0
vllm serve ${model_path} \
 --dtype ${data_type} \
 --host 0.0.0.0 \
 --port ${port} \
 --trust-remote-code \
 -tp 8 \
 --gpu-memory-utilization $gpu_memory \
 --disable-log-requests \
 --max-model-len 73216 \
 --max-num-batched-tokens 16384 \
 -cc '{"pass_config": {"fuse_act_quant": false}, "cudagraph_mode": "full", "custom_ops": ["all"]}' \
 -q slimquant_marlin \
 --kv-cache-dtype fp8_e4m3 \
 --enable-prefix-caching \
 --disable-cascade-attn \
 2>&1 | tee "${log_dir}/serve_${time}.log"

#### BW1000

```bash
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3
```

#### K100_AI

不需要--kv-cache-dtype 参数

## MiniMax-M2_5-Channel-FP8-w8a8(内部量化)

https://www.modelscope.cn/models/hygon/MiniMax-M2.5-Channel-FP8-w8a8

### 测试模式

#### nmz

```bash
rm -rf ~/.cache
rm -rf ~/.triton
rm -rf /tmp/torchinductor_root/
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=3
export VLLM_RANK1_NUMA=1
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=7
export VLLM_RANK5_NUMA=5
export VLLM_RANK6_NUMA=5
export VLLM_RANK7_NUMA=4
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000
export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0
export VLLM_USE_OPT_ZEROS=1
export VLLM_USE_PD_SPLIT=1
```

# export VLLM_TORCH_PROFILER_DIR=/home/work/prof/
export VLLM_TORCH_PROFILER_DIR=/mnt/claw/torchprof
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=1
export VLLM_USE_LIGHTOP=1
export LMSLIM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1 #moe_sum融合
# 替换lightop接口
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1
export VLLM_USE_OPT_RESHAPE_AND_CACHE=1
# chunksize设置为16384
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化
export VLLM_FUSED_MOE_CHUNK_SIZE=16384  # --max-num-batched-tokens 16384
export VLLM_USE_PIECEWISE=1
export VLLM_USE_LIGHTOP_FUSED_TOPP_TOPK=1
export VLLM_USE_OPT_OP=1 #新加变量
model_path=/mnt/model/MiniMax-M2___5-Channel-FP8-w8a8
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
port=7888
gpu_memory=0.92
bwtype="nmz1100"
# bwtype="bw1000"
log_date=$(date "+%Y-%m-%d")
log_dir="${bwtype}_${model}/${log_date}"
mkdir -p "${log_dir}"
export VLLM_USE_AITER_MOE_W8A8=0
vllm serve ${model_path} \
 --dtype ${data_type} \
 --host 0.0.0.0 \
 --port ${port} \
 --trust-remote-code \
 -tp 4 -pp 2 \
 --gpu-memory-utilization $gpu_memory \
 --disable-log-requests \
 --max-model-len 73216 \
 --max-num-batched-tokens 16384 \
 -cc '{"pass_config": {"fuse_act_quant": false}, "cudagraph_mode": "full", "custom_ops": ["all"]}' \
 -q slimquant_marlin \
 --kv-cache-dtype fp8_e4m3 \
 --enable-prefix-caching \
 --disable-cascade-attn \
 2>&1 | tee "${log_dir}/serve_${time}.log"

## MiniMax-M2.5-bf16

### 测试模式

```bash
rm -rf ~/.cache
rm -rf ~/.triton
rm -rf /tmp/torchinductor_root/
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=1
export VLLM_RANK5_NUMA=1
export VLLM_RANK6_NUMA=1
export VLLM_RANK7_NUMA=1
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000
export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0
export VLLM_USE_OPT_ZEROS=1
export VLLM_USE_PD_SPLIT=1
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=1
export VLLM_USE_LIGHTOP=1
export LMSLIM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1 #moe_sum融合
```

# 替换lightop接口
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1
# chunksize设置为16384
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化
export VLLM_FUSED_MOE_CHUNK_SIZE=16384  # --max-num-batched-tokens 16384
export VLLM_USE_PIECEWISE=1
export VLLM_USE_LIGHTOP_FUSED_TOPP_TOPK=1
export VLLM_USE_OPT_OP=1 #新加变量
export VLLM_USE_AITER_MOE_W8A8=0
model_path=/mnt/model/MiniMax-M2.5-bf16
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
port=7888
gpu_memory=0.92
bwtype="nmz1100"
# bwtype="bw1000"
log_date=$(date "+%Y-%m-%d")
log_dir="${bwtype}_${model}/${log_date}"
mkdir -p "${log_dir}"
#--kv-cache-dtype fp8_e5m2
vllm serve ${model_path} \
 --dtype ${data_type} \
 --host 0.0.0.0 \
 --port ${port} \
 --trust-remote-code \
 -tp 8 \
 --gpu-memory-utilization $gpu_memory \
 --disable-log-requests \
 --max-model-len 73216 \
 --max-num-batched-tokens 16384 \
 -cc '{"pass_config": {"fuse_act_quant": false}, "cudagraph_mode": "full", "custom_ops": ["all"]}' \
 --enable-prefix-caching \
 --disable-cascade-attn \
 --kv-cache-dtype fp8_e4m3 \
 2>&1 | tee "${log_dir}/serve_${time}.log"

#### BW1000

```bash
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3
```

#### K100_AI

预估需要双机16卡,目前暂无最佳实践

## Qwen3-32B

### 测试模式

```bash
rm -rf ~/.cache/
rm -rf ~/.triton/

export HIP_VISIBLE_DEVICES=4,5,6,7
export VLLM_USE_LIGHTOP=1
export LMSLIM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1
export VLLM_USE_OPT_RESHAPE_AND_CACHE=1
export VLLM_USE_GLOBAL_CACHE13=1
export VLLM_FUSED_MOE_CHUNK_SIZE=16384
export VLLM_USE_PIECEWISE=1
export VLLM_USE_LIGHTOP_FUSED_TOPP_TOPK=1

model_path=/mnt/model/qwen3/Qwen3-32B
model=${model_path##*/}
tp=4
time=$(date "+%m%d-%H%M")
```

#mode="eager"
mode="cudagraph"
logpath="./logs-server"
data_type="fp16"
port=8239
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

vllm serve $model_path \
    -tp 4 \
    --port $port \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --kv-cache-dtype fp8_e5m2 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}' \
    2>&1 | tee  ${logpath}/${model}_$time.log

#### BW1000

```bash
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3
```

#### K100_AI

不需要--kv-cache-dtype 参数

## Qwen2.5-VL-72B-Instruct

### 测试模式

```bash
pip uninstall transformers -y
pip install transformers==4.57 -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn

rm -rf ~/.cache/
rm -rf ~/.triton/

export HIP_VISIBLE_DEVICES=4,5,6,7
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_SPEC_DECODE_EAGER=1
export VLLM_ZERO_OVERHEAD=1 # zero
export VLLM_TORCH_PROFILER_DIR=/mnt/torchprof

model_path=/mnt/model/qwen2.5/Qwen2.5-VL-72B-Instruct
model=${model_path##*/}
tp=4
time=$(date "+%m%d-%H%M")
```

#mode="eager"
mode="cudagraph"
logpath="./logs-server"
data_type="fp16"
port=8239
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

#--max-num-seqs 1024
#--enforce-eager
#--kv-cache-dtype fp8_e4m3
vllm serve $model_path \
        --host 0.0.0.0 \
        --port $port   \
        --dtype  float16 \
        --kv-cache-dtype fp8_e4m3 \
        --tensor-parallel-size $tp   \
        --trust-remote-code  \
        --distributed-executor-backend=mp \
        --disable-cascade-attn \
        2>&1 | tee  ${logpath}/${model}_$time.log

#### BW1000

```text
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```text
 --kv-cache-dtype fp8_e4m3
```

#### K100_AI

有bug

## Qwen2.5-VL-72B-Instruct-quantized.w8a8（社区量化）

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
```

#export VLLM_PCIE_USE_CUSTOM_ALLREDUCE=1  #k100ai
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=1
export VLLM_RANK5_NUMA=1
export VLLM_RANK6_NUMA=1
export VLLM_RANK7_NUMA=1



model_path=/mnt/model/vllm-w8a8-models/Qwen2.5-VL-72B-Instruct-quantized.w8a8/
model=${model_path##*/}
time=$(date "+%m%d-%H:%M")
data_type="float16"
tp=4
logpath="./server/0515/bmz/vllm015/Qwen2.5-VL-72B-Instruct-int8-e5m2"

port=8140
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

VLLM_USE_PD_SPLIT=1  VLLM_USE_V1=1 vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype bfloat16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --no-enable-prefix-caching \
    --no-enable-chunked-prefill \
    --max-num-seqs 1024 \
    --disable-cascade-attn --kv-cache-dtype fp8_e4m3 \
    --max-model-len 40960 \
    --limit-mm-per-prompt '{"image": 255, "video": 1}'  >&1 | tee  ${logpath}/server.log

#### BW1000

```text
修改为：--kv-cache-dtype fp8_e5m2
```

#### NMZ

```text
同测试模式
```

#### K100_AI

```text
去掉参数：--kv-cache-dtype fp8_e4m3
```

## GLM-5-w4a8-V2_6_test（非社区量化）

```bash
rm -rf ~/.cache
rm -rf ~/.triton

export VLLM_USE_MODELSCOPE=1
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
```

#===============融合算子=================
export USE_FUSED_RMS_QUANT=1 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0

export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 #default 1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 # 不能和kvfp8一起开
export VLLM_USE_V32_ENCODE=1
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1

MODEL_PATH=/mnt/model/v2_6/GLM-w4a8-V2_6_test/

vllm serve "$MODEL_PATH" \
    -q slimquant_w4a8_marlin \
    --port 8000 \
    --trust-remote-code \
    --dtype bfloat16 \
    -tp 8 \
    --max-model-len 72000 \
    --gpu-memory-utilization 0.92 \
    --disable-log-requests \
    --enable-chunked-prefill \
    --max-num-batched-tokens 16384 \
    --enable-prefix-caching \
    --kv-cache-dtype fp8_ds_mla \
    -cc '{"pass_config": {"fuse_act_quant": false}}' \
    --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_w4a8_marlin"}' >&1 | tee server/server-GLM-5-w4a8-tp8-0515-nmz.log

#### BW1000

```text
同测试模式
```

#### NMZ

```text
同测试模式
```

#### K100_AI

不支持

## GLM-5-W8A8（社区量化）

### 测试模式

```bash
export VLLM_USE_MODELSCOPE=1
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
```

#===============融合算子=================
export USE_FUSED_RMS_QUANT=1 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0

export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 #default 1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 # 不能和kvfp8一起开
export VLLM_USE_V32_ENCODE=1
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1

vllm serve /mnt/model/vllm-w8a8-models/GLM-5-W8A8/  \
    -q slimquant_marlin \
    --trust-remote-code \
    --dtype bfloat16 \
    -tp 8 \
    --max-model-len 72000 \
    --gpu-memory-utilization 0.92 \
    --disable-log-requests \
    --enable-chunked-prefill \
    --max-num-batched-tokens 16384 \
    --enable-prefix-caching \
    --kv-cache-dtype fp8_ds_mla \
    -cc '{"pass_config": {"fuse_act_quant": false}}' \
    --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_marlin"}'  >&1 | tee server/server-GLM-5-w8a8-tp8-0515-nmz.log

#### BW1000

```text
同测试模式，16卡测试
```

#### NMZ

```text
同测试模式
```

#### K100_AI

不支持

## GLM5-Channelwise-FP8-quantized（社区量化）

### 测试模式

```bash
rm -rf ~/.cache
rm -rf ~/.triton
```

#export VLLM_TORCH_PROFILER_DIR=/prof
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PIECEWISE=1 # 需暂时打开piecewise，fullgraph有精度问题
export VLLM_REJECT_SAMPLE_OPT=1 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
#===============融合算子=================
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0
#===============共享专家融合 已知精度异常=============
export VLLM_ROCM_USE_AITER=0 #default 0
export VLLM_ROCM_USE_AITER_MOE=0 #default 0
export VLLM_ROCM_USE_AITER_FUSION_SHARED_EXPERTS=0 #default 0
#注意：--compilation-config中需要添加"custom_ops": ["all", "+rms_norm"]
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 #default 1(mtp可能存在精度问题)
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0 #w4a16/awq # 需要关闭
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 # 不能和kvfp8一起开
export VLLM_USE_V32_ENCODE=1
export VLLM_USE_FLASH_MLA=1
export VLLM_DISABLE_DSA=0
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1
# export LMSLIM_USE_LIGHTOP=1

# 零调度消耗
export VLLM_ZERO_OVERHEAD=1
export VLLM_ZERO_NO_THREAD=1

# 新的lmslim包添加
export VLLM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1

export VLLM_USE_OPT_OP=1
export USE_LIGHTOP_TOPK=1

# VLLM_LOGGING_LEVEL=DEBUG
# MODEL_PATH="/models/GLM-5-FP8"
MODEL_PATH="/mnt/model/vllm-fp8-models/GLM5-Channelwise-FP8-quantized/"

TP=8
PORT=12580

# ===== 日志目录 =====
LOG_ROOT="./prof"
mkdir -p ${LOG_ROOT}
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_DIR="${LOG_ROOT}/${TIMESTAMP}"
mkdir -p ${LOG_DIR}

LOG_FILE="${LOG_DIR}/vllm.log"

# ===== Prof 目录 =====
export VLLM_TORCH_PROFILER_DIR="./prof/${TIMESTAMP}"
mkdir -p "${VLLM_TORCH_PROFILER_DIR}"

echo "日志保存到 ${LOG_FILE}"
echo "Prof 保存到 ${VLLM_TORCH_PROFILER_DIR}"

# ===== 启动 vLLM 服务并记录日志 =====
vllm serve "$MODEL_PATH" \
    -q slimquant_marlin \
    --port 12580 \
    --trust-remote-code \
    --dtype bfloat16 \
    -tp 8  \
    --max-model-len 36000 \
    --gpu-memory-utilization 0.9 \
    --disable-log-requests \
    --no-enable-prefix-caching \
    --max-num-batched-tokens 16384 \
    --enable-chunked-prefill \
    --kv-cache-dtype fp8_ds_mla \
    -cc '{"pass_config": {"fuse_act_quant": false}}' \
    --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_marlin"}' \
    2>&1 | tee ${LOG_FILE}

#### BW1000

```text
同测试模式，16卡测试
```

#### NMZ

```text
同测试模式
```

#### K100_AI

不支持

## DeepSeek-R1-Distill-Llama-70B

### 测试模式

```bash
export VLLM_HCU_USE_FLASH_ATTN=1
export VLLM_HCU_USE_FLASH_ATTN_UNIFIED=1
export VLLM_HCU_USE_CUSTOM_TOPK_TOPP_SAMPLER=1

model_path="/model4/DeepSeek-R1-Distill-Llama-70B"
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8132
export HIP_VISIBLE_DEVICES=0,1


log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"


vllm serve ${model_path} \
    -tp 2 \
    --dtype bfloat16 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"
```

#### BW1000

```text
同测试模式
```

#### NMZ

```text
同测试模式
```

#### K100_AI

```bash
model_path="/model4/DeepSeek-R1-Distill-Llama-70B"
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8132
export HIP_VISIBLE_DEVICES=0,1


log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"


vllm serve ${model_path} \
    -tp 2 \
    --dtype bfloat16 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"
```

## DeepSeek-R1-Distill-Qwen-32B

### 测试模式

```bash
```

#!/bin/bash

export VLLM_HCU_USE_FLASH_ATTN=1
export VLLM_HCU_USE_FLASH_ATTN_UNIFIED=1
export VLLM_HCU_USE_CUSTOM_TOPK_TOPP_SAMPLER=1
export HIP_VISIBLE_DEVICES=2,3

model_path="/model/deepseek-r1/DeepSeek-R1-Distill-Qwen-32B"
model=${model_path##*/} 
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8132 

log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"

vllm serve ${model_path} \
    -tp 2 \
    --dtype bfloat16 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"

#### BW1000

```text
同测试模式
```

#### NMZ

```text
同测试模式
```

#### K100_AI

```bash

export HIP_VISIBLE_DEVICES=2,3

model_path="/model/deepseek-r1/DeepSeek-R1-Distill-Qwen-32B"
model=${model_path##*/} 
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8132 

log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"

vllm serve ${model_path} \
    -tp 2 \
    --dtype bfloat16 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"
```

## GLM4.7-w8a8

bf16原版模型去除marlin测试

#### NMZ

```text
export VLLM_TORCH_PROFILER_DIR=./prof-0310
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export NCCL_P2P_NVL_CHUNKSIZE=131072
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=1
export VLLM_RANK5_NUMA=1
export VLLM_RANK6_NUMA=1
export VLLM_RANK7_NUMA=1
export VLLM_USE_GLOBAL_CACHE13=1
export VLLM_FUSED_MOE_CHUNK_SIZE=8192
export VLLM_ZERO_OVERHEAD=1
```

#export VLLM_W8A8_BACKEND=1
export VLLM_USE_PD_SPLIT=1
export HIP_USE_GRAPH_QUEUE_POOL=1
export VLLM_USE_LIGHTOP=1
export VLLM_USE_PIECEWISE=1

export SENDRECV_STREAM_WITH_COMPUTE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export GATHER_STREAM_WITH_COMPUTE=1
export Allgather_Base_STREAM_WITH_COMPUTE=1

export USE_FUSED_SILU_MUL_QUANT=1 
export USE_FUSED_RMS_QUANT=1 
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=1

export VLLM_USE_AITER_MOE_W8A8=0
#暂时规避一下
#关闭优化项和宽松采样验证humaneval
export USE_FUSED_SILU_MUL_QUANT=0
export USE_FUSED_RMS_QUANT=0
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=0
export VLLM_REJECT_SAMPLE_OPT=0
vllm serve /model/GLM-4.7-W8A8  --disable-cascade-attn  --host 0.0.0.0 --port 9348 -q slimquant_marlin --trust-remote-code --disable-log-requests -tp 8 --max-num-seqs 256  --max-model-len 40960 --gpu-memory-utilization 0.9 --max_num_batched_tokens 40960  --enable-chunked-prefill --enable-prefix-caching --dtype bfloat16  -cc '{"inductor_compile_config":{"combo_kernels": false}}' --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_marlin"}'

#### BW1000

```text
同NMZ测试模式
```

#### K100-AI

关闭marlin

```text
export VLLM_TORCH_PROFILER_DIR=./prof-0310
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export NCCL_P2P_NVL_CHUNKSIZE=131072
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=1
export VLLM_RANK5_NUMA=1
export VLLM_RANK6_NUMA=1
export VLLM_RANK7_NUMA=1
export VLLM_USE_GLOBAL_CACHE13=1
export VLLM_FUSED_MOE_CHUNK_SIZE=8192
export VLLM_ZERO_OVERHEAD=1
```

#export VLLM_W8A8_BACKEND=1
export VLLM_USE_PD_SPLIT=1
export HIP_USE_GRAPH_QUEUE_POOL=1
export VLLM_USE_LIGHTOP=1
export VLLM_USE_PIECEWISE=1

export SENDRECV_STREAM_WITH_COMPUTE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export GATHER_STREAM_WITH_COMPUTE=1
export Allgather_Base_STREAM_WITH_COMPUTE=1

export USE_FUSED_SILU_MUL_QUANT=1 
export USE_FUSED_RMS_QUANT=1 
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=1

export VLLM_USE_AITER_MOE_W8A8=0
#暂时规避一下
#关闭优化项和宽松采样验证humaneval
export USE_FUSED_SILU_MUL_QUANT=0
export USE_FUSED_RMS_QUANT=0
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=0
export VLLM_REJECT_SAMPLE_OPT=0
vllm serve /model/GLM-4.7-W8A8  --disable-cascade-attn  --host 0.0.0.0 --port 9348  --trust-remote-code --disable-log-requests -tp 8 --max-num-seqs 256  --max-model-len 40960 --gpu-memory-utilization 0.9 --max_num_batched_tokens 40960  --enable-chunked-prefill --enable-prefix-caching --dtype bfloat16  -cc '{"inductor_compile_config":{"combo_kernels": false}}' --speculative_config '{"method": "mtp", "num_speculative_tokens": 2}'

## GLM5.1-Channel-INT8

#### NMZ

```text
rm -rf ~/.cache
rm -rf ~/.triton

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7     
export ALLREDUCE_STREAM_WITH_COMPUTE=1           
export NCCL_MIN_NCHANNELS=16                      
export NCCL_MAX_NCHANNELS=16                   
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1   
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PIECEWISE=0
```

#export VLLM_REJECT_SAMPLE_OPT=1 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1

#===============融合算子=================
export USE_FUSED_RMS_QUANT=1 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0

#===============共享专家融合 已知精度异常=============
export VLLM_ROCM_USE_AITER=0 #default 0
export VLLM_ROCM_USE_AITER_MOE=0 #default 0
export VLLM_ROCM_USE_AITER_FUSION_SHARED_EXPERTS=0 #default 0

export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 #default 1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 # 不能和kvfp8一起开
export VLLM_USE_V32_ENCODE=1
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1

export VLLM_USE_AITER_MOE_W8A8=0

export VLLM_REJECT_SAMPLE_OPT=0
export USE_FUSED_SILU_MUL_QUANT=0
export USE_FUSED_RMS_QUANT=0
export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=0
MODEL_PATH=/model1/GLM-5.1-Channel-INT8

vllm serve "$MODEL_PATH" \
    -q slimquant_marlin \
    --disable-cascade-attn \
    --port 9350 \
    --trust-remote-code \
    --dtype bfloat16 \
    -tp 8 \
    --max-model-len 40960 \
    --gpu-memory-utilization 0.92 \
    --disable-log-requests \
    --enable-chunked-prefill \
    --max-num-batched-tokens 16384 \
    --enable-prefix-caching \
    --kv-cache-dtype fp8_ds_mla \
    -cc '{"pass_config": {"fuse_act_quant": false}}' \
    --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_marlin"}'

## GLM5.1-Channel-FP8

#### NMZ

精度轻微问题待解决

```bash
rm -rf ~/.cache
rm -rf ~/.triton

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7     
export ALLREDUCE_STREAM_WITH_COMPUTE=1           
export NCCL_MIN_NCHANNELS=16                      
export NCCL_MAX_NCHANNELS=16                   
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1   
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PIECEWISE=0
export VLLM_REJECT_SAMPLE_OPT=1 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
```

#export VLLM_REJECT_SAMPLE_OPT=0
#===============融合算子=================
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0

#===============共享专家融合 已知精度异常=============
export VLLM_ROCM_USE_AITER=0 #default 0
export VLLM_ROCM_USE_AITER_MOE=0 #default 0
export VLLM_ROCM_USE_AITER_FUSION_SHARED_EXPERTS=0 #default 0

export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 #default 1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 # 不能和kvfp8一起开
export VLLM_USE_V32_ENCODE=1
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1

export VLLM_USE_AITER_MOE_W8A8=0

#export USE_FUSED_SILU_MUL_QUANT=0
#export USE_FUSED_RMS_QUANT=0
#export VLLM_V1_USE_FUSED_QKV_SPLIT_RMS_ROPE_KVSTORE=0

MODEL_PATH=/model1/GLM-5.1-Channel-fp8

vllm serve "$MODEL_PATH" \
    -q slimquant_marlin \
    --disable-cascade-attn \
    --port 9350 \
    --trust-remote-code \
    --dtype bfloat16 \
    -tp 8 \
    --max-model-len 40960 \
    --gpu-memory-utilization 0.92 \
    --disable-log-requests \
    --enable-chunked-prefill \
    --max-num-batched-tokens 16384 \
    --enable-prefix-caching \
    --kv-cache-dtype fp8_ds_mla \
    -cc '{"pass_config": {"fuse_act_quant": false}}' \
    --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_marlin"}'

## Qwen3-VL-30B-A3B-Thinking

### 测试模式

nmz可选择使用fp8_e4m3,bw1000可选择使用fp8_e5m2

vllm015镜像需降级transformer至4.57.0版本

可选：    --max-num-batched-tokens 20480

```bash
export HIP_VISIBLE_DEVICES=6,7
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=5
export VLLM_RANK1_NUMA=4
export VLLM_USE_PIECEWISE=1
model_path=/model/Qwen3-VL-30B-A3B-Thinking/
model=${model_path##*/}
time=$(date "+%m%d-%H:%M")
data_type="float16"
tp=2
logpath="./server/vllm011/bw1000/Qwen3-VL-30B-Thinking/"
port=9229

if [ ! -d "${logpath}" ]; then
    mkdir -p "${logpath}"
fi
vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 \
    --enable-prefix-caching --enable-chunked-prefill --disable-cascade-attn >&1 | tee  ${logpath}.log
```

#### BW1000

可选    --kv-cache-dtype fp8_e5m2 \

--max-num-batched-tokens 20480

```bash
vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 \
    --kv-cache-dtype fp8_e5m2 \
    --max-num-batched-tokens 20480 --enable-prefix-caching --enable-chunked-prefill --disable-cascade-attn >&1 | tee  ${logpath}.log
```

#### NMZ

可选    --kv-cache-dtype fp8_e4m3 \
    --max-num-batched-tokens 20480

```bash
vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 \
    --kv-cache-dtype fp8_e4m3 \
    --max-num-batched-tokens 20480 --enable-prefix-caching --enable-chunked-prefill --disable-cascade-attn >&1 | tee  ${logpath}.log
```

#### K100_AI

区别：tp4

可选  --max-num-batched-tokens 20480

```text
vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 \
    --enable-prefix-caching --enable-chunked-prefill --disable-cascade-attn >&1 | tee  ${logpath}.log
```

## DeepSeek-R1-Channel-INT8

#### 测试模式

```bash
```

#w8a8最佳实践环境变量
rm -rf ~/.cache
rm -rf ~/.triton
#w8a8最佳实践环境变量
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
export VLLM_USE_PIECEWISE=1 #atten eager下发，影响性能，设为0性能更好 default 1
#===============融合算子=================
export VLLM_SPEC_DECODE_EAGER=0 #MTP使用eager下发default 0
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768

export USE_FUSED_RMS_QUANT=1  #int8开
export USE_FUSED_SILU_MUL_QUANT=1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=1

export VLLM_USE_FLASH_ATTN_FP8=0 #int8不开
export VLLM_USE_CAT_MLA=1
export VLLM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1

time=$(date "+%Y-%m-%d-%H-%M-%S")
model_test=DeepSeek-R1-Channel-INT8
log_date=$(date "+%Y-%m-%d")
log_dir="./server/${model_test}/${log_date}"
mkdir -p "${log_dir}"

vllm serve /model/DeepSeek-R1-Channel-INT8 \
--trust-remote-code \
-q slimquant_marlin \
-tp 8 \
--dtype bfloat16 \
--max-model-len 35000 \
--disable-log-requests \
--gpu-memory-utilization 0.90 \
--max-num-batched-tokens 16384 \
--no-enable-prefix-caching \
--compilation-config '{"pass_config": {"fuse_act_quant": false}}' \
--speculative_config '{"method": "deepseek_mtp", "num_speculative_tokens": 2,"quantization": "slimquant_marlin"}' \
 2>&1 | tee "${log_dir}/serve_${time}.log"

#### BW1000

JavaScript
有bug，待重新测试
#===============多机增加=================
export VLLM_HOST_IP=12.12.12.41
export NCCL_SOCKET_IFNAME=ens47f0np0
export GLOO_SOCKET_IFNAME=ens47f0np0
export NCCL_IB_HCA=mlx5_0:1,mlx5_1:1,mlx5_2:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,mlx6_1:1,mlx5_8:1,mlx5_9:1  #按照实际
export NCCL_NET_GDR_READ=1
#===============多机增加=================

BMZ带--kv-cache-dtype gsm8k精度有问题

#### NMZ

```text
 --kv-cache-dtype fp8_e4m3
```

#### K100-AI

JavaScript
有bug，待重新测试

## DeepSeek-R1-Channe-FP8

#### 测试模式

```bash
```

#w8a8最佳实践环境变量
rm -rf ~/.cache
rm -rf ~/.triton
#w8a8最佳实践环境变量
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
export VLLM_USE_PIECEWISE=1 #atten eager下发，影响性能，设为0性能更好 default 1
#===============融合算子=================
export VLLM_SPEC_DECODE_EAGER=0 #MTP使用eager下发default 0
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768

export USE_FUSED_RMS_QUANT=0
export USE_FUSED_SILU_MUL_QUANT=1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=1

export VLLM_USE_FLASH_ATTN_FP8=1
export VLLM_USE_CAT_MLA=1
export VLLM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1

time=$(date "+%Y-%m-%d-%H-%M-%S")
model_test=DeepSeek-R1-Channel-FP8
log_date=$(date "+%Y-%m-%d")
log_dir="./server/${model_test}/${log_date}"
mkdir -p "${log_dir}"

vllm serve /model/vllm-fp8-models/DeepSeek-R1-Channel-FP8 \
--trust-remote-code \
-q slimquant_marlin \
-tp 8 \
--dtype bfloat16 \
--max-model-len 35000 \
--disable-log-requests \
--gpu-memory-utilization 0.90 \
--max-num-batched-tokens 16384 \
--no-enable-prefix-caching \
--compilation-config '{"pass_config": {"fuse_act_quant": false}}' \
--speculative_config '{"method": "deepseek_mtp", "num_speculative_tokens": 2,"quantization": "slimquant_marlin"}' \
 --kv-cache-dtype fp8_e4m3 \
 2>&1 | tee "${log_dir}/serve_${time}.log"

#### BW1000

```text
不支持fp8
```

#### NMZ

```text
同测试模式
```

#### K100-AI

```text
不支持fp8
```

## Qwen3-VL-235B-A22B-Instruct

需降级transformers：pip install transformers==4.57 -i https://pypi.tuna.tsinghua.edu.cn/simple

### 测试模式

环境变量：

```bash
export VLLM_HOST_IP=12.12.12.74
export NCCL_SOCKET_IFNAME=ib0
export GLOO_SOCKET_IFNAME=ib0
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_IB_HCA=mlx5_0:1,mlx5_2:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,,mlx5_6:1,mlx5_7:1,mlx5_8:1,mlx5_9:1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000
export NCCL_TOPO_FILE="/public/home/chenwch/zhumc/topo-input.xml"
unset NCCL_ALGO
export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0
export VLLM_USE_OPT_ZEROS=1
export VLLM_USE_V1=1
export VLLM_ZERO_OVERHEAD=0
export RAY_CGRAPH_get_timeout=18000
export RAY_DAG_GET_TIMEOUT_S=18000
export VLLM_USE_PD_SPLIT=1
export VLLM_ENABLE_TBO=0

export VLLM_SCHED_ENABLE_MINIMAL_INJECTION=1
export VLLM_USE_FUSE_SILU_AND_MUL=0
export VLLM_USE_FUSED_RMS_ROPE=0
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=0
export VLLM_USE_LIGHTOP_MOE_ALIGN=0
export VLLM_USE_OPT_RESHAPE_AND_CACHE=0

server：

Bash
model_path=/public/opendas/DL_DATA/llm-models/Qwen3-VL-235B-A22B-Instruct
model=${model_path##*/}
tp=16
logpath="./server/Qwen3-VL-235B-A22B-Instruct/"
current_time=$(date +"%Y%m%d-%H%M")
logpath="./Qwen3-VL-235B-A22B-Instruct/${model}-tp${tp}-${current_time}"
port=8100
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi
```

#
python3 -m vllm.entrypoints.openai.api_server \
 --model ${model_path} \
 --dtype float16 \
 --host 0.0.0.0 \
 --port ${port} \
 -tp ${tp}  \
 --gpu-memory-utilization 0.9 \
 --trust-remote-code \
 --distributed-executor-backend ray \
 --block-size 64 \
 --max-num-seq 256 \
 --max-num-batched-tokens 32768 \
 --max-model-len 32768 \
 --enable-chunked-prefill \
 --no-enable-prefix-caching   >&1 | tee  ${logpath}.log

#### BW1000

```text
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```text
--kv-cache-dtype fp8_e4m3
-tp8
```

#### K100_AI

```bash
export VLLM_PCIE_USE_CUSTOM_ALLREDUCE=1 #K100AI
```

## Qwen3-Coder-480B-A35B-Instruct-w8a8

#### 测试模式

```bash
export VLLM_HOST_IP=12.12.12.42
export NCCL_SOCKET_IFNAME=ens47f0np0
export GLOO_SOCKET_IFNAME=ens47f0np0
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_IB_HCA=mlx5_0:1,mlx5_1:1,mlx5_2:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,mlx5_6:1,mlx5_8:1,mlx5_9:1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export NCCL_NET_GDR_READ=1
export VLLM_RPC_TIMEOUT=1800000

unset NCCL_ALGO
export NCCL_NET_GDR_LEVEL=7
export NCCL_SDMA_COPY_ENABLE=0

export VLLM_USE_PIECEWISE=0
export VLLM_USE_FUSED_FILL_RMS_CAT=0
export VLLM_USE_FUSED_RMS_ROPE=0
export VLLM_USE_AITER_MOE_W8A8=0
```

#起服务

vllm serve /public/opendas/DL_DATA/llm-models/Qwen3-Coder-480B-A35B-Instruct-W8A8 \
  --trust-remote-code \
  --dtype bfloat16 \
  --max-model-len 262144 \
  -tp 16 \
  --gpu-memory-utilization 0.9 \
  --max-num-seqs 128 \
  --block-size 64 \
  --max-num-batched-tokens 16384 \
  --no-enable-prefix-caching \
  --enable-chunked-prefill \
  --compilation-config '{"pass_config": {"fuse_act_quant": false}}'

#### BW1000

```text
--kv-cache-dtype fp8_e5m2
```

#### NMZ

```bash
--kv-cache-dtype fp8_e4m3 
-tp 8
```

#### K100_AI

```text
export VLLM_PCIE_USE_CUSTOM_ALLREDUCE=1 #K100AI
```

## Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic

#### 测试模式

```bash
```

# NUMA绑定，提高RCCL稳定性
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3
# 通信调优参数
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export VLLM_RPC_TIMEOUT=1800000



export LD_LIBRARY_PATH=/opt/rocblas-install/lib:$LD_LIBRARY_PATH
export VLLM_USE_PIECEWISE=0
export VLLM_USE_FUSED_FILL_RMS_CAT=0
export VLLM_USE_FUSED_RMS_ROPE=0
export VLLM_USE_AITER_MOE_W8A8=0
#起服务

vllm serve /public/opendas/DL_DATA/llm-models/qwen3/Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic \
  --trust-remote-code \
  --dtype bfloat16 \
  --max-model-len 262144 \
  -tp 8 \
  --gpu-memory-utilization 0.9 \
  --max-num-seqs 128 \
  --block-size 64 \
  --max-num-batched-tokens 16384 \
  --no-enable-prefix-caching \
  --enable-chunked-prefill \
  --kv-cache-dtype fp8_e4m3 \
  --compilation-config '{"pass_config": {"fuse_act_quant": false}}'

#### BW1000

```text
不支持fp8
```

#### NMZ

```bash
同测试模式
```

#### K100_AI

```text
不支持fp8
```

## DeepSeek-R1-0528-W4A8-V2

#### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000

export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
export VLLM_USE_PIECEWISE=1 #atten eager下发，影响性能，设为0性能更好 default 0
```

#===============融合算子=================
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0
#===============共享专家融合 已知精度异常=============
export VLLM_ROCM_USE_AITER=0 #default 0
export VLLM_ROCM_USE_AITER_MOE=0 #default 0
export VLLM_ROCM_USE_AITER_FUSION_SHARED_EXPERTS=0 #default 0
#注意：--compilation-config中需要添加"custom_ops": ["all", "+rms_norm"]

export VLLM_SPEC_DECODE_EAGER=0 #MTP使用eager下发default 0
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1

export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0

export VLLM_USE_V32_ENCODE=1
export VLLM_USE_FLASH_MLA=1

log_date=$(date "+%Y-%m-%d")
log_dir="./${log_date}"
if ! mkdir -p "${log_dir}"; then
    exit 1
fi
model_path=/public/opendas/DL_DATA/llm-models/vllm-w8a8-models/DeepSeek-R1-0528-W4A8-V2
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
tp=8
port=8082
gpu_memory=0.90
#--speculative_config '{"method": "deepseek_mtp", "num_speculative_tokens": 3}'
vllm serve ${model_path} \
 --port ${port} \
 --trust-remote-code \
 --dtype ${data_type} \
 --max-model-len 40960 \
 -q slimquant_w4a8_marlin \
 -tp ${tp} \
 --gpu-memory-utilization ${gpu_memory} \
 --max-num-seqs 256 \
 --max-num-batched-tokens 8192 \
 --block-size 64 \
 --speculative_config '{"method": "mtp", "num_speculative_tokens": 2, "quantization": "slimquant_w4a8_marlin"}' \
 --enable-chunked-prefill \
 --enable-prefix-caching \
 --kv-cache-dtype fp8_e5m2 \
 2>&1 | tee "${log_dir}/${model}_serve_${time}.log"

#### BW1000

```text
同测试模式
```

#### NMZ

```bash

export HIP_VISIBLE_DEVICES=0,1,2,3
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
export VLLM_USE_PIECEWISE=1 #atten eager下发，影响性能，设为0性能更好 default 0
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0
```

#===============融合算子=================
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0
# export VLLM_SPEC_DECODE_EAGER=0 #MTP使用eager下发default 0
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=8192 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1
export VLLM_USE_FLASH_MLA=1
export VLLM_USE_CAT_MLA=1
log_date=$(date "+%Y-%m-%d")
log_dir="./${log_date}"
if ! mkdir -p "${log_dir}"; then
    exit 1
fi
model_path=/public/opendas/DL_DATA/llm-models/vllm-w8a8-models/DeepSeek-R1-0528-W4A8-V2
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
tp=4
port=8082
gpu_memory=0.90
vllm serve ${model_path} \
 --port ${port} \
 --trust-remote-code \
 --dtype ${data_type} \
 --max-model-len 40960 \
 -q slimquant_w4a8_marlin \
 -tp ${tp} \
 --gpu-memory-utilization ${gpu_memory} \
 --max-num-seqs 256 \
 --max-num-batched-tokens 8192 \
 --block-size 64 \
 --enable-chunked-prefill \
 --enable-prefix-caching \
 --kv-cache-dtype fp8 \
 --speculative_config '{"method": "mtp", "num_speculative_tokens": 3, "quantization": "slimquant_w4a8_marlin"}' \
 2>&1 | tee "${log_dir}/${model}_serve_${time}.log"

#### K100_AI

```text
暂无
```

## Qwen3-4B-Thinking-2507

#### 测试模式

```text

time=$(date "+%Y-%m-%d-%H-%M-%S")
model_test=Qwen3-4B-Thinking-2507
log_date=$(date "+%Y-%m-%d")
log_dir="./server/${model_test}/${log_date}"
mkdir -p "${log_dir}"

vllm serve /model/qwen3/Qwen3-4B-Thinking-2507 \
    -tp 1 \
    --max-num-batched-tokens 10240 \
    --trust-remote-code \
    --disable-cascade-attn \
     2>&1 | tee "${log_dir}/serve_${time}.log"
```

#### bw1000

```text
同测试模式
```

#### NMZ

```text
同测试模式
```

#### k100_AI

```text
同测试模式
```

## QwQ-32B

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3
model_path=/model/QwQ-32B/

model=${model_path##*/}
time=$(date "+%m%d-%H%M")
data_type="float16"
tp=4
logpath="/mnt/tfcc_new/vllm/benchmarks/tc_opt/logs/QwQ-32B/${time}"
port=8000
if [ ! -d ${logpath} ]; then
    mkdir -p ${logpath}
fi
```

# 在后台启动 vllm serve
vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --gpu-memory-utilization 0.9 \
    --trust-remote-code \
    --max-num-seqs 1024 --distributed-executor-backend=mp --no-enable-prefix-caching  --disable-cascade-attn  2>&1 | tee  ${logpath}/serve-kaixiang-0112-jingdu.log &

### BW1000

Python
--kv-cache-dtype fp8_e5m2

### NMZ

Python
--kv-cache-dtype fp8_e4m3

### K100_AI

```bash
暂无
```

## DeepSeek-R1-bf16

```bash
```

#待测试
rm -rf ~/.cache
rm -rf ~/.triton
export VLLM_HOST_IP=$(hostname -I | awk '{print $2}')
echo $VLLM_HOST_IP
export VLLM_USE_FUSED_FILL_RMS_CAT=0
export NCCL_SOCKET_INNAME=ib0
export GLOO_SOCKET_INNAME=ib0
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_IB_HCA=mxlx5_2:1,mxlx5_3:1,mxlx5_4:1,mxlx5_5:1,mxlx5_6:1,mxlx5_7:1,mxlx5_8:1,mxlx5_9:1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export NCCL_P2P_NVL_CHUNKSIZE=131072
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=3
export VLLM_RANK1_NUMA=1
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=0
export VLLM_RANK4_NUMA=7
export VLLM_RANK5_NUMA=5
export VLLM_RANK6_NUMA=5
export VLLM_RANK7_NUMA=4
export VLLM_USE_GLOBAL_CACHE=1
export VLLM_FUSED_MOE_CHUNK_SIZE=8192
export VLLM_ZERO_OVERHEAD=1
export VLLM_USE_PD_SPLIT=1
export HIP_USE_GRAPH_QUEUE_POOL=1
export VLLM_USE_LIGHTOP=1
export VLLM_USE_PIECEWISE=0
export SENDRECV_STREAM_WITH_COMPUTE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export GATHER_STREAM_WITH_COMPUTE=1
export Allgather_Base_STREAM_WITH_COMPUTE=1
model_path=/module/DeepSeek-R1-bf16
model=${model_path##*/}
data_type="bfloat16"
tp=32
port=8828
gpu_memory=0.9
log_date=$(date "+%Y-%m-%d")
time=$(date "+%Y-%m-%d-%H-%M-%S")
log_dir="bw1000_${model}/${log_date}"
mkdir -p "${log_dir}"
vllm serve ${model_path} \
  --trust-remote-code \
  --distributed-executor-backend ray \
  --dtype $data_type \
  --tensor-parallel-size $tp \
  --gpu-memory-utilization $gpu_memory \
  --host 0.0.0.0 \
  --port $port \
  --max-model-len 40960 \
  --disable-log-requests \
  --block-size 64 \
  --speculative_config '{"method": "mtp", "num_speculative_tokens": 3}' \
  -cc '{"inductor_compile_config":{"combo_kernels": false}}' \
  --enable-chunked-prefill \
  --no-enable-prefix-caching \
  --disable-cascade-attn \
  2>&1 | tee "${log_dir}/serve_${time}.log"

### BW1000

Python
待测试

### NMZ

Python
待测试

### K100_AI

```bash
待测试
```

## Qwen3-Next-80B-A3B-Instruct

```bash
export HIP_VISIBLE_DEVICES=1,2,3,4
```

#export VLLM_CUSTOM_CACHE=0
model_path=/models/qwen3/Qwen3-Next-80B-A3B-Instruct
data_type="float16"
tp=4
port=8806
vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --gpu-memory-utilization 0.9 \
    --max-num-seqs 1024 \
    --trust-remote-code  --distributed-executor-backend=mp --no-enable-prefix-caching  --disable-cascade-attn

### BW1000

暂无

### NMZ

暂无

### K100_AI

进入容器需要修改代码：修改 /usr/local/lib/python3.10/dist-packages/vllm/v1/attention/ops/triton_unified_attention.py中的996行，将if not use_fa_unified_2d改为True

## Qwen3-0.6B/Qwen3-4B

```text
export HIP_VISIBLE_DEVICES=2
vllm serve /models/qwen3/Qwen3-0.6B  \
    -tp 1 \
    --trust-remote-code \
    --disable-log-requests \
    --dtype bfloat16 \
    --port 8001 \
    --disable-cascade-attn \
    -cc '{"pass_config": {"fuse_act_quant": false}, "custom_ops": ["all"]}'
```

### BW1000

```text
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PICEWISE=1
```

### NMZ

```text
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PICEWISE=1
```

### K100_AI

暂无

## Qwen3.5-122B-A10B

```bash

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
model_path=/models/qwen3.5/Qwen3.5-122B-A10B
data_type="float16"
tp=8
port=8809
vllm serve  /models/qwen3.5/Qwen3.5-122B-A10B  \
    -tp 8 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --speculative-config.method mtp \
    --speculative-config.num_speculative_tokens 3
```

### BW1000

```text
export VLLM_HCU_USE_FLASH_ATTN=1
export VLLM_HCU_USE_FLASH_ATTN_UNIFIED=1
export VLLM_HCU_USE_CUSTOM_TOPK_TOPP_SAMPLER=1
```

### NMZ

```text
export VLLM_HCU_USE_FLASH_ATTN=1
export VLLM_HCU_USE_FLASH_ATTN_UNIFIED=1
export VLLM_HCU_USE_CUSTOM_TOPK_TOPP_SAMPLER=1
```

### K100_AI

暂无

## GLM-4-32B-0414

### 测试模式

测试报错  有bug

```bash
export HIP_VISIBLE_DEVICES=4
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
```

#export VLLM_PCIE_USE_CUSTOM_ALLREDUCE=1  #k100ai
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=1
export VLLM_RANK1_NUMA=1

export VLLM_USE_OPT_ZEROS=1

export VLLM_ZERO_OVERHEAD=1 # zero

export VLLM_USE_PD_SPLIT=1
export VLLM_USE_V1=1

export VLLM_USE_FLASH_ATTN_PA=0 #需要禁用fa


model_path=/mnt/model/glm4/GLM-4-32B-0414/


#export LD_LIBRARY_PATH=/hyq/tfcc/rocblas-install-1127-bug111580/rocblas-install/lib/:$LD_LIBRARY_PATH

model=${model_path##*/}
time=$(date "+%m%d-%H%M")
data_type="bfloat16"
tp=1
logpath="./server/0428/nmz/vllm015/GLM-4-32B-0414/${time}"
port=8164
if [ ! -d ${logpath} ]; then
    mkdir -p ${logpath}
fi

vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype bfloat16 --tensor-parallel-size $tp \
    --gpu-memory-utilization 0.9 \
    --trust-remote-code \
    --max-num-seqs 1024 \
    --distributed-executor-backend=mp \
    --enable-prefix-caching  \
    --enable-chunked-prefill --disable-log-requests --kv-cache-dtype fp8_e5m2  2>&1 | tee  ${logpath}/serve.log

### bw1000

```text
同测试模式
```

### NMZ

```text
同测试模式
```

### k100ai

```text
去除 --kv-cache-dtype fp8_e5m2
```

## DeepSeek-V3.1-Terminus-fp8

### 测试模式

```bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_USE_PD_SPLIT=1
export VLLM_USE_PIECEWISE=1 # 需暂时打开piecewise，fullgraph有精度问题
export VLLM_REJECT_SAMPLE_OPT=1 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
```

#===============融合算子=================
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=0 #default 0
#===============共享专家融合 已知精度异常=============
export VLLM_ROCM_USE_AITER=0 #default 0
export VLLM_ROCM_USE_AITER_MOE=0 #default 0
export VLLM_ROCM_USE_AITER_FUSION_SHARED_EXPERTS=0 #default 0
#注意：--compilation-config中需要添加"custom_ops": ["all", "+rms_norm"]
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=16384 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1 #default 1(mtp可能存在精度问题)
export VLLM_USE_LIGHTOP_MOE_SUM_MUL_ADD=0 #w4a16/awq # 需要关闭
export VLLM_USE_LIGHTOP_RMS_ROPE_CONCAT=0 # 不能和kvfp8一起开
export VLLM_USE_V32_ENCODE=1
export VLLM_USE_FLASH_MLA=1
export VLLM_DISABLE_DSA=0
export USE_LIGHTOP_TOPK=1
export USE_LIGHTOP_PER_TOKEN_GROUP_QUANT_FP8=1
export USE_LIGHTOP_CONVERT_REQ_INDEX_TO_GLOBAL_INDEX=1
# export LMSLIM_USE_LIGHTOP=1

# 零调度消耗
export VLLM_ZERO_OVERHEAD=1
export VLLM_ZERO_NO_THREAD=1

# 新的lmslim包添加
export VLLM_USE_LIGHTOP=1
export VLLM_USE_LIGHTOP_FILL_MOE_ALIGN=1

export VLLM_USE_OPT_OP=1
export USE_LIGHTOP_TOPK=1
#export VLLM_USE_FLASH_ATTN_FP8=1

model_path=/mnt/model/deepseek-v3.1/DeepSeek-V3.1-Terminus/
model=${model_path##*/}
time=$(date "+%m%d-%H:%M")
data_type="bfloat16"
tp=8
logpath="./server/0226/nmz/DeepSeek-V3.1-Terminus-fp8-tp8-vllm/"
port=9348
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

#--kv-cache-dtype fp8_e4m3 \
#--speculative_config '{"method": "deepseek_mtp", "num_speculative_tokens": 1}' \

vllm serve ${model_path} \
 --trust-remote-code \
 --dtype $data_type \
 --tensor-parallel-size $tp \
 --gpu-memory-utilization 0.9 \
 --disable-cascade-attn \
 --host 0.0.0.0 \
 --port $port \
 --block-size 64 \
 --max-model-len 40960 \
 --max-num-batched-tokens 8192 \
 --enable-prefix-caching  \
 --speculative_config '{"method": "deepseek_mtp", "num_speculative_tokens": 1}'  --enforce-eager 2>&1 | tee "${logpath}/serve_${time}.log"

### bw1000

不支持

### NMZ

```text
同测试模式
```

### k100ai

不支持

## DeepSeek-R1-Distill-Llama-70B-quantized.w8a8

### 测试模式

```bash
export VLLM_HCU_USE_FLASH_ATTN=1
export VLLM_HCU_USE_FLASH_ATTN_UNIFIED=1
export VLLM_HCU_USE_CUSTOM_TOPK_TOPP_SAMPLER=1

model_path="/model/vllm-w8a8-models/DeepSeek-R1-Distill-Llama-70B-quantized.w8a8"
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8132
export HIP_VISIBLE_DEVICES=6,7

log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"


vllm serve ${model_path} \
    -tp 2 \
    --dtype bfloat16 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"
```

### bw1000

```text
同测试模式
```

### NMZ

```text
同测试模式
```

### k100ai

```bash
export HIP_VISIBLE_DEVICES=4,5,6,7
model_path="/model/vllm-w8a8-models/DeepSeek-R1-Distill-Llama-70B-quantized.w8a8"
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8132

log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/k100ai/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"


vllm serve ${model_path} \
    -tp 4 \
    --dtype bfloat16 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"
```

## Qwen3.5-35B-A3B & Qwen3.5-35B-A3B-W8A8

### 测试模式

此模型在nmz与bmz使用单卡跑，在k100ai中使用双卡跑

```text
export VLLM_HCU_USE_FLASH_ATTN=1
export VLLM_HCU_USE_FLASH_ATTN_UNIFIED=1
export VLLM_HCU_USE_CUSTOM_TOPK_TOPP_SAMPLER=1
export HIP_VISIBLE_DEVICES=0

model_path="/model/qwen3.5/Qwen3.5-35B-A3B"
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8133 # 端口号，你可以根据需要自行修改

log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"
```

# ==========================================
# 启动 vLLM Server
# ==========================================
echo "Starting vLLM server on port ${port}..."
echo "Logs will be saved to: ${log_dir}/serve_${time}.log"

vllm serve ${model_path} \
    -tp 1 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --speculative-config.method mtp \
    --speculative-config.num_speculative_tokens 3 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"

### bw1000

```text
同测试模式
```

### nmz

```text
同测试模式
```

### k100ai

```bash
export VLLM_HCU_USE_CUSTOM_QUANTIZATION_GEMM=0
export VLLM_HCU_USE_CUSTOM_OPS=0
export HIP_VISIBLE_DEVICES=0,1
model_path="/model/qwen3.5/Qwen3.5-35B-A3B"
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
port=8133 

log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/k100ai/server_logs/vllm/${model}/${log_date}"
mkdir -p "${log_dir}"

echo "Starting vLLM server on port ${port}..."
echo "Logs will be saved to: ${log_dir}/serve_${time}.log"

vllm serve ${model_path} \
    -tp 2 \
    --trust-remote-code \
    --disable-cascade-attn \
    --max-num-batched-tokens 10240 \
    --speculative-config.method mtp \
    --speculative-config.num_speculative_tokens 3 \
    --host 0.0.0.0 \
    --port $port \
    2>&1 | tee "${log_dir}/serve_${time}.log"
```

## DeepSeek-V3-W4A8-V2

### 测试模式

```bash
rm -rf ~/.cache
rm -rf ~/.triton
export VLLM_TORCH_PROFILER_DIR=/public/home/yangql/26_pages/vllm015/dpsk_r1_mla_bug_prof
export HIP_VISIBLE_DEVICES=4,5,6,7
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export Allgather_Base_STREAM_WITH_COMPUTE=1
export SENDRECV_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_REJECT_SAMPLE_OPT=0 # 宽松采样，提高mtp接受率从而提高tpot性能，略微影响精度 default 1
export VLLM_USE_PIECEWISE=1 #atten eager下发，影响性能，设为0性能更好 default 0
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0
```

#===============融合算子=================
export USE_FUSED_RMS_QUANT=0 #default 0
export USE_FUSED_SILU_MUL_QUANT=1 #default 0
# export VLLM_SPEC_DECODE_EAGER=0 #MTP使用eager下发default 0
export VLLM_USE_GLOBAL_CACHE13=1 #减少显存碎片化 default 0
export VLLM_FUSED_MOE_CHUNK_SIZE=8192 #default 32768
export VLLM_CUSTOM_CACHE=1 #default 1
export VLLM_USE_OPT_CAT=1
export VLLM_USE_FUSED_FILL_RMS_CAT=1
export VLLM_USE_FLASH_MLA=1
export VLLM_USE_CAT_MLA=1
log_date=$(date "+%Y-%m-%d")
log_dir="/mnt/data_log/nmz/server_logs/vllm/${model}/${log_date}"
if ! mkdir -p "${log_dir}"; then
    exit 1
fi
model_path=/model/vllm-w8a8-models/DeepSeek-V3-W4A8-V2
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="bfloat16"
tp=4
port=8132
gpu_memory=0.90
vllm serve ${model_path} \
 --port ${port} \
 --trust-remote-code \
 --dtype ${data_type} \
 --max-model-len 40960 \
 -q slimquant_w4a8_marlin \
 -tp ${tp} \
 --gpu-memory-utilization ${gpu_memory} \
 --max-num-seqs 256 \
 --max-num-batched-tokens 8192 \
 --block-size 64 \
 --enable-chunked-prefill \
 --served-model-name dpsk \
 --enable-prefix-caching \
 --speculative_config '{"method": "mtp", "num_speculative_tokens": 3, "quantization": "slimquant_w4a8_marlin"}' \
 2>&1 | tee "${log_dir}/${model}_serve_${time}.log"

### nmz

```text
 --kv-cache-dtype fp8 \
```

### bw1000

精度有问题

### k100ai

server报错  有bug

## Qwen3-VL-32B-Instruct

### 测试模式

需要将transformers到4.57.0版本

```bash

export HIP_VISIBLE_DEVICES=0,1
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=1
export VLLM_RANK3_NUMA=1
export VLLM_RANK4_NUMA=2
export VLLM_RANK5_NUMA=2
export VLLM_RANK6_NUMA=3
export VLLM_RANK7_NUMA=3
export VLLM_USE_PD_SPLIT=1

model_path=/model/qwen3/Qwen3-VL-32B-Instruct
model=${model_path##*/}
time=$(date "+%Y-%m-%d-%H-%M-%S")
data_type="float16"
tp=2
port=8132
gpu_memory=0.9

bwtype="nmz"
```

# bwtype="bw1000"
log_date=$(date "+%Y-%m-%d")
logpath="/mnt/data_log/nmz/server_logs/vllm/${model}_${time}"

mkdir -p "${logpath}"

vllm serve ${model_path} \
 --trust-remote-code \
 --dtype ${data_type} \
 --host 0.0.0.0 \
 --port ${port} \
 -tp ${tp} \
 --max-num-batched-tokens 20480 \
 --gpu-memory-utilization $gpu_memory \
 --enable-chunked-prefill \
 --no-enable-prefix-caching \
 --disable-cascade-attn \
 2>&1 | tee "${logpath}/serve_${time}.log"

### bw1000

```text
 --kv-cache-dtype fp8_e5m2 \
```

### nmz

```text
 --kv-cache-dtype fp8_e4m3 \
```

### k100ai

```text
同测试模式
```

## Qwen2.5-VL-32B-Instruct

### 测试模式

需要将transformers到4.57.0版本

```bash
export HIP_VISIBLE_DEVICES=6,7
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=0
export VLLM_RANK1_NUMA=0
export VLLM_RANK2_NUMA=0
export VLLM_RANK3_NUMA=0
export VLLM_USE_OPT_ZEROS=1
model_path=/model/qwen2.5/Qwen2.5-VL-32B-Instruct
model=${model_path##*/}
time=$(date "+%m%d-%H:%M")
data_type="float16"
tp=2
logpath="/mnt/data_log/nmz/server_logs/vllm/${model}_${time}"
port=8132
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi
VLLM_USE_PD_SPLIT=1  VLLM_USE_V1=1 vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --max-model-len 128000 --no-enable-prefix-caching --enable-chunked-prefill --distributed-executor-backend=mp  --disable-cascade-attn  >&1 | tee  ${logpath}.log
```

### bw1000

```text
    --kv-cache-dtype fp8_e5m2 \
```

### nmz

```text
    --kv-cache-dtype fp8_e4m3 \
```

### k100ai

```text
同测试模式
```

## Qwen3-VL-4B-Instruct

### 测试模式

需要将transformers到4.57.0版本

```bash
export HIP_VISIBLE_DEVICES=1,2
export HSA_FORCE_FINE_GRAIN_PCIE=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_P2P_LEVEL=SYS
export NCCL_LAUNCH_MODE=GROUP
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export VLLM_RPC_TIMEOUT=1800000
export VLLM_NUMA_BIND=1
export VLLM_RANK0_NUMA=3
export PYTORCH_MIOPEN_SUGGEST_NDHWC=0

model_path=/model/qwen3/Qwen3-VL-4B-Instruct
model=${model_path##*/}
time=$(date "+%m%d-%H:%M")
data_type="float16"
tp=2

logpath="/mnt/data_log/bmz/server_logs/vllm/${model}_${time}"
port=8132
if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

VLLM_USE_PD_SPLIT=1  VLLM_USE_V1=1 vllm serve ${model_path} \
    --host 0.0.0.0 --port $port \
    --dtype float16 --tensor-parallel-size $tp \
    --trust-remote-code \
    --limit-mm-per-prompt '{"image": 15}' \
    --gpu_memory_utilization 0.90 \
    --no-enable-prefix-caching --disable-cascade-attn \
    2>&1 | tee  ${logpath}.log
```

### bw1000

```text
    --kv-cache-dtype fp8_e5m2 \
```

### nmz

```text
    --kv-cache-dtype fp8_e4m3 \
```

### k100ai

```text
同测试模式
```
