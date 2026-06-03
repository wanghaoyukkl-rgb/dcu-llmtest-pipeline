# SGLANG测试指导

（1）模型为二级标题；测试模式为三级标题；加速卡为四级标题；

（2）本文已隐去人员标记，仅保留模型测试方案信息；

（3）模型名称需要与社区命名一致；如果是量化模型需要明确是社区量化还是内部量化；

（4）如果不同加速卡有测试区别，需要在不同加速卡下明确，相同部分全部放在加速卡上统一编写；

（5）总结出来测试方法，不明确具体镜像；

（6）注意编写格式，如使用代码块，编写整洁；

# 导航

## 统一设置

## MiniMax\-M2\.5\-Channel\-INT8\-w8a8

### 测试模式

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_USE_LIGHTOP=1
#export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export LMSLIM_USE_LIGHTOP=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model/MiniMax-M2.5-Channel-INT8-w8a8
#export HIP_VISIBLE_DEVICES=4,5,6,7
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
host_ip=$(hostname -I | awk '{print $1}')
port=30000
hostname=$(hostname)
master_ip=$host_ip
max_model_len=131072
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 1 1 3 4 5 5 4"
option+=" --chunked-prefill-size 16384"
option+=" --max-running-requests 512 "
option+=" --context-length $max_model_len"

python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e4m3 \
                                --trust-remote-code  --page-size 64 \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp --data-parallel-size $dp    --tool-call-parser minimax-m2 \
                                --reasoning-parser minimax-append-think  \
                                --mem-fraction-static $gpu_mem --attention-backend fa3 --disable-radix-cache \
                                2>&1 | tee  ${logpath}-$time.log

```

#### BW1000

```Bash
--kv-cache-dtype bfloat16
```

#### K100AI:

暂无

## MiniMax\-M2\_\_\_5\-Channel\-FP8\-w8a8

### 测试模式

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_USE_LIGHTOP=1
#export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export LMSLIM_USE_LIGHTOP=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model/MiniMax-M2___5-Channel-FP8-w8a8
#export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
host_ip=$(hostname -I | awk '{print $1}')
port=30002
hostname=$(hostname)
master_ip=$host_ip
max_model_len=131072
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
#option="--numa-node 3 1 1 0"
option+=" --chunked-prefill-size 16384"
option+=" --max-running-requests 512 "
option+=" --context-length $max_model_len"

python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                 --quantization w8a8_fp8 --kv-cache-dtype fp8_e4m3 \
                                --trust-remote-code  --page-size 64 \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp --data-parallel-size $dp  \
                                --reasoning-parser minimax-append-think  \
                                --mem-fraction-static $gpu_mem --attention-backend fa3 --disable-radix-cache 2>&1 | tee  ${logpath}-$time.log

```

## MiniMax\-M2\.5\-bf16

### 测试模式

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_USE_LIGHTOP=1
#export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export VLLM_USE_LIGHTOP_MOE_ALIGN=1
export LMSLIM_USE_LIGHTOP=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model/MiniMax-M2.5-bf16
#export HIP_VISIBLE_DEVICES=4,5,6,7
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
nodes=1
rank=0
host_ip=$(hostname -I | awk '{print $1}')
port=30000
hostname=$(hostname)
master_ip=$host_ip
max_model_len=131072
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

#option="--numa-node 0 0 0 0 1 1 1 1 "
option="--numa-node 0 1 1 3 4 5 5 4"
option+=" --chunked-prefill-size 16384"
option+=" --max-running-requests 512 "
option+=" --context-length $max_model_len"

python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --kv-cache-dtype fp8_e4m3 \
                                --trust-remote-code  --page-size 64 \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp --data-parallel-size $dp    --tool-call-parser minimax-m2 \
                                --reasoning-parser minimax-append-think  \
                                --mem-fraction-static $gpu_mem --attention-backend fa3 --disable-radix-cache \
                                2>&1 | tee  ${logpath}-$time.log


```

#### BW1000

```Bash
--kv-cache-dtype bfloat16
```

#### K100AI:

暂无

## Qwen2\.5\-VL\-72B\-Instruct

### 测试模式

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
export HIP_VISIBLE_DEVICES=4,5,6,7
model_path=/model/qwen2.5/Qwen2.5-VL-72B-Instruct
model=${model_path##*/}
tp=4
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e4m3  --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port  \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

#### BW1000

```Bash
--kv-cache-dtype bfloat16
```

#### K100AI:

```Bash
-tp 8 \
--kv-cache-dtype bfloat16
```

## GLM5\-Channelwise\-FP8\-quantized

### 测试模式

#### NMZ

```SQL
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_FP8_W8A8_MOE=1
export SGLANG_ROCM_USE_AITER_MOE=0
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0

mkdir -p <LOCAL_PATH>
MODEL_PATH="/model/vllm-fp8-models/GLM5-Channelwise-FP8-quantized"
export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

sglang serve \
  --model-path $MODEL_PATH \
  --trust-remote-code \
  --tp-size 8 \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_kv \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype fp8_e4m3 \
  --mem-fraction-static 0.9 \
  --chunked-prefill-size 8192 \
  --cuda-graph-max-bs 32 \
  --max-running-requests 32 \
  --reasoning-parser glm45 \
  --tool-call-parser glm47 \
  --speculative-algorithm EAGLE \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 2>&1 | tee <LOCAL_PATH>
```

## GLM\-5\-W8A8

### 测试模式

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
export SGLANG_USE_MODELSCOPE=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=0
export HIP_H2D_DISABLE_COPY_BUFFER=0
export HIP_D2H_DISABLE_COPY_BUFFER=0
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768
export HIP_D2H_DIRECT_COPY_THRESHOLD=512
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export HIP_GRAPH_USE_CMD_CACHE=0
export NCCL_SOCKET_IFNAME=ens19f0
export GLOO_SOCKET_IFNAME=ens19f0
export NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=3

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

sglang serve \
  --model-path /model/vllm-w8a8-models/GLM-5-W8A8 \
  --trust-remote-code \
  --tp-size 8 \
  --kv-cache-dtype fp8_e4m3 \
  --dtype bfloat16 \
  --page-size 64 \
  --quantization slimquant_marlin \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_kv \
  --mem-fraction-static 0.8 2>&1 | tee <LOCAL_PATH>
```

#### BW1000

```Bash
#!/bin/bash

export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_GRAPH_ACCUMULATE_DISPATCH=0
export HIP_H2D_DISABLE_COPY_BUFFER=0
export HIP_D2H_DISABLE_COPY_BUFFER=0
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768
export HIP_D2H_DIRECT_COPY_THRESHOLD=512
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512

export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ROCSHMEM_DISABLE_HDP_FLUSH=1
export ROCSHMEM_GDA_NUM_QPS_DEFAULT_CTX=288
export ROCSHMEM_HEAP_SIZE=3173741824
export SGLANG_DEEPEP_NUM_MAX_DISPATCH_TOKENS_PER_RANK=128
export ROCSHMEM_ALLOWED_IBV_DEVICES=mlx5_0

export SGLANG_USE_LIGHTOP=1

export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_ROCM_USE_AITER_MOE=0

export NCCL_SOCKET_IFNAME="ens61f0np0"
export GLOO_SOCKET_IFNAME="ens61f0np0"
export NCCL_IB_HCA="mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9"

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

model_path=/model/vllm-w8a8-models/GLM-5-W8A8
model=${model_path##*/}
tp=16
pp=1
dp=1
ep=1
nodes=2
rank=$1
host_ip="<HOST_IP>"
master_ip=$host_ip
gpu_mem=0.8
port=30000
dist_port=5000
time=$(date "+%m%d-%H%M")
logfile="<LOCAL_PATH>"

# option=" --disable-radix-cache"
option+=" --page-size 64"
option+=" --nsa-prefill-backend flashmla_sparse --nsa-decode-backend flashmla_sparse"
option+=" --quantization slimquant_marlin"

python_cmd="python3 -m sglang.launch_server --model-path "${model_path}" ${option} \
                                --trust-remote-code \
                                --kv-cache-dtype bf16 --dtype bfloat16 --mem-fraction-static "${gpu_mem}" \
                                --port "${port}" --dist-init-addr "${master_ip}:${dist_port}" \
                                --nnodes "${nodes}" --node-rank "${rank}" \
                                --tp-size "${tp}" --pp-size "${pp}" --dp-size "${dp}" --ep-size "${ep}""

echo "Executing: ${python_cmd}"

${python_cmd} 2>&1 | tee "${logfile}"
```

#### KME

flash\_mla算子对kme不支持，[internal-link-removed]

## GLM\-5\-w4a8

### 测试模式

#### NMZ

```SQL
export NCCL_SOCKET_IFNAME="ens19f0"
export GLOO_SOCKET_IFNAME="ens19f0"
export NCCL_IB_HCA="mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9"
export NCCL_IB_GID_INDEX=3
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export MC_ENABLE_DEST_DEVICE_AFFINITY=1
export MC_GID_INDEX=3
export SGLANG_USE_LIGHTOP=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export W8A8_SUPPORT_METHODS=3
# mtp需要
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
sysctl -w kernel.numa_balancing=0 || true

MODEL_PATH="<LOCAL_PATH>"

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

python3 -m sglang.launch_server \
  --model-path "${MODEL_PATH}" \
  --port 30000 \
  --tp-size 8 \
  --pp-size 1 \
  --dp-size 1 \
  --ep-size 1 \
  --trust-remote-code \
  --dtype bfloat16 \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_kv \
  --kv-cache-dtype fp8_e4m3 \
  --mem-fraction-static 0.85 \
  --chunked-prefill-size 8192 \
  --quantization slimquant_w4a8_marlin \
  --reasoning-parser glm45 \
  --tool-call-parser glm47 \
  --speculative-algorithm EAGLE \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 \
  2>&1 | tee <LOCAL_PATH>
```

#### BW1000

```Bash
#!/bin/bash
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=3
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9
export NCCL_SOCKET_IFNAME=ens19f0
export GLOO_SOCKET_IFNAME=ens19f0
export NCCL_IB_GID_INDEX=3
export SGLANG_USE_MODELSCOPE=1

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

sglang serve \
  --model-path <LOCAL_PATH> \
  --trust-remote-code \
  --tp-size 8 \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_sparse \
  --quantization slimquant_w4a8_marlin \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype bf16 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
  --reasoning-parser glm45 \
  --tool-call-parser glm47 \
  --speculative-algorithm EAGLE \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 \
  2>&1 | tee <LOCAL_PATH>
```

#### KME

flash\_mla算子对kme不支持，[internal-link-removed]



## GLM\-5\.1\-FP8

### 测试模式

#### NMZ

```SQL
# 0525
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_FP8_W8A8_MOE=1
export SGLANG_ROCM_USE_AITER_MOE=0
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0

mkdir -p <LOCAL_PATH>
MODEL_PATH="/share/GLM-5.1-Channel-fp8"
export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

sglang serve \
  --model-path $MODEL_PATH \
  --trust-remote-code \
  --tp-size 8 \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_kv \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype fp8_e4m3 \
  --mem-fraction-static 0.9 \
  --chunked-prefill-size 8192 \
  --cuda-graph-max-bs 32 \
  --max-running-requests 32 \
  --reasoning-parser glm45 \
  --tool-call-parser glm47 \
  --speculative-algorithm EAGLE \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 2>&1 | tee <LOCAL_PATH>
```

## GLM\-5\.1\-W8A8

### 测试模式

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
export SGLANG_USE_MODELSCOPE=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=0
export HIP_H2D_DISABLE_COPY_BUFFER=0
export HIP_D2H_DISABLE_COPY_BUFFER=0
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768
export HIP_D2H_DIRECT_COPY_THRESHOLD=512
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export HIP_GRAPH_USE_CMD_CACHE=0
export NCCL_SOCKET_IFNAME=ens19f0
export GLOO_SOCKET_IFNAME=ens19f0
export NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=3

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

sglang serve \
  --model-path /share/GLM-5.1-Channel-INT8 \
  --trust-remote-code \
  --tp-size 8 \
  --kv-cache-dtype fp8_e4m3 \
  --dtype bfloat16 \
  --page-size 64 \
  --quantization slimquant_marlin \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_kv \
  --mem-fraction-static 0.8 2>&1 | tee <LOCAL_PATH>
```

#### BW1000

```Bash
#!/bin/bash

export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_GRAPH_ACCUMULATE_DISPATCH=0
export HIP_H2D_DISABLE_COPY_BUFFER=0
export HIP_D2H_DISABLE_COPY_BUFFER=0
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768
export HIP_D2H_DIRECT_COPY_THRESHOLD=512
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512

export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ROCSHMEM_DISABLE_HDP_FLUSH=1
export ROCSHMEM_GDA_NUM_QPS_DEFAULT_CTX=288
export ROCSHMEM_HEAP_SIZE=3173741824
export SGLANG_DEEPEP_NUM_MAX_DISPATCH_TOKENS_PER_RANK=128
export ROCSHMEM_ALLOWED_IBV_DEVICES=mlx5_0

export SGLANG_USE_LIGHTOP=1

export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_ROCM_USE_AITER_MOE=0

export NCCL_SOCKET_IFNAME="ens61f0np0"
export GLOO_SOCKET_IFNAME="ens61f0np0"
export NCCL_IB_HCA="mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9"

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

model_path=/share/GLM-5.1-Channel-INT8
model=${model_path##*/}
tp=16
pp=1
dp=1
ep=1
nodes=2
rank=$1
host_ip="<HOST_IP>"
master_ip=$host_ip
gpu_mem=0.8
port=30000
dist_port=5000
time=$(date "+%m%d-%H%M")
logfile="<LOCAL_PATH>"

# option=" --disable-radix-cache"
option+=" --page-size 64"
option+=" --nsa-prefill-backend flashmla_sparse --nsa-decode-backend flashmla_sparse"
option+=" --quantization slimquant_marlin"

python_cmd="python3 -m sglang.launch_server --model-path "${model_path}" ${option} \
                                --trust-remote-code \
                                --kv-cache-dtype bf16 --dtype bfloat16 --mem-fraction-static "${gpu_mem}" \
                                --port "${port}" --dist-init-addr "${master_ip}:${dist_port}" \
                                --nnodes "${nodes}" --node-rank "${rank}" \
                                --tp-size "${tp}" --pp-size "${pp}" --dp-size "${dp}" --ep-size "${ep}""

echo "Executing: ${python_cmd}"

${python_cmd} 2>&1 | tee "${logfile}"
```

#### KME

flash\_mla算子对kme不支持，[internal-link-removed]



## GLM\-5\.1\-w4a8

### 测试模式

#### NMZ

```SQL
export NCCL_SOCKET_IFNAME="ens19f0"
export GLOO_SOCKET_IFNAME="ens19f0"
export NCCL_IB_HCA="mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9"
export NCCL_IB_GID_INDEX=3
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export MC_ENABLE_DEST_DEVICE_AFFINITY=1
export MC_GID_INDEX=3
export SGLANG_USE_LIGHTOP=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export W8A8_SUPPORT_METHODS=3
# mtp需要
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
sysctl -w kernel.numa_balancing=0 || true

MODEL_PATH="/models1/GLM-5.1-W4A8-V2_6"

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

python3 -m sglang.launch_server \
  --model-path "${MODEL_PATH}" \
  --port 30000 \
  --tp-size 8 \
  --pp-size 1 \
  --dp-size 1 \
  --ep-size 1 \
  --trust-remote-code \
  --dtype bfloat16 \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_kv \
  --kv-cache-dtype fp8_e4m3 \
  --mem-fraction-static 0.85 \
  --chunked-prefill-size 8192 \
  --quantization slimquant_w4a8_marlin \
  --reasoning-parser glm45 \
  --tool-call-parser glm47 \
  --speculative-algorithm EAGLE \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 \
  2>&1 | tee <LOCAL_PATH>

# --nsa-prefill-backend flashmla_auto

```

#### BW1000

```Bash
#!/bin/bash
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=3
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
# export NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9
# export NCCL_SOCKET_IFNAME=ens19f0
# export GLOO_SOCKET_IFNAME=ens19f0
# export NCCL_IB_GID_INDEX=3
# export SGLANG_USE_MODELSCOPE=1

mkdir -p <LOCAL_PATH>

export TZ=Asia/Shanghai
time=$(date +"%Y%m%d-%H%M%S")
echo "当前时间：$time"

sglang serve \
  --model-path /models1/GLM-5.1-W4A8-V2_6 \
  --trust-remote-code \
  --tp-size 8 \
  --nsa-prefill-backend flashmla_auto \
  --nsa-decode-backend flashmla_sparse \
  --quantization slimquant_w4a8_marlin \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype bf16 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
  --speculative-algorithm EAGLE \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 \
  2>&1 | tee <LOCAL_PATH>
```

#### KME

flash\_mla算子对kme不支持，[internal-link-removed]

## Ling\-T\-FP8

### 测试模式

#### NMZ

```Shell
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_FP8_W8A8_MOE=1
export SGLANG_USE_FUSED_BAILING_RMS_QUANT=1
export SGLANG_USE_FUSED_BAILING_SILU_MUL_FP8_QUANT=1
export SGLANG_USE_FUSED_BAILING_RMS_ROTARY=1

# custom_allreduce no memory copy
export HIP_KERNEL_EVENT_SYSTENFENCE=1

model_path=/model/inclusionAI/Ling-1T-FP8
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
nodes=1
rank=0
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$host_ip
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 1 1 2 2 3 3"

python3 -m sglang.launch_server ${option}  \
  --trust-remote-code \
  --host $host_ip --port 30000 \
  --model-path $model_path \
  --attention-backend fa3 --page-size 64 \
  --tp-size $tp --kv-cache-dtype fp8_e4m3 --pp-size $pp \
  --mem-fraction-static $gpu_mem \
  2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

## Qwen3\.5\-397B

### 测试模式

#### NMZ

```Bash
#!/bin/bash

port=${1:-30005}
model_path=${2:-/model/qwen3.5/Qwen3.5-397B-A17B}
model=${model_path##*/}
the_host=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')

net_ifname=enp9s0f4u1c2
#time
time=$(date "+%m%d-%H%M")


echo "---- Current Env Variables Setup ------"
env_vars=(
    "NCCL_MIN_NCHANNELS=16"
    "NCCL_MAX_NCHANNELS=16"
    "SGLANG_ENABLE_SPEC_V2=1"
    "SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile"
    "HSA_ENABLE_COREDUMP=1"
    "USE_DCU_CUSTOM_ALLREDUCE=1" # default using vllm allreduce, if set to 1, ALLREDUCE_STREAM_WITH_COMPUTE has to be set to 1, optimize for graph mode
    "ALLREDUCE_STREAM_WITH_COMPUTE"
    "HIP_KERNEL_EVENT_SYSTENFENCE=1"       # default using vllm allreduce, optimize for egar mode
    "SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0" # default stay
    "GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000" # default stay
    "HIP_KERNEL_BATCH_CEILING=100"    # default stay
    "GPU_FORCE_BLIT_COPY_SIZE=16"     # default stay
    "HSA_KERNARG_POOL_SIZE=8388608"   # default stay
    "ROC_AQL_QUEUE_SIZE=131072"       # default stay
    "SGLANG_USE_LIGHTOP=1"            # enable lightop rope and topk kernel
#    "SGLANG_USE_FP8_W8A8_MOE=1"       # using lightop fp8 moe kernel
    "SGLANG_USE_FUSED_TOPK_SOFTMAX=1" # Specially for topk of Qwen-model and bailing
    "SGLANG_USE_CAUSAL_CONV1D=1"
    "SGLANG_USE_MARLIN_W16A16_MOE=1" #int8/int4不需要
    # "SGLANG_USE_FUSED_GEMMRMS_QUANT=1"
    # "SGLANG_USE_FUSED_RMS_ROTARY=1"
    "SGLANG_KV_LAYOUT_DCU_FA=1" # default enable, using optimized PA layout
    "SGLANG_USE_AITER_LINEAR_ATTN=1"
)
for kv in "${env_vars[@]}"; do
    export "$kv"
    echo "export $kv"
done

sysctl -w kernel.numa_balancing=0

echo "---- Current Running Cmd ------"
tp_size=8
pp_size=1
dp_size=1
ep_size=1
#host_ip=0.0.0.0
DEFAULT_ARGS=(
    --numa-node 0 0 0 0 1 1 1 1     # 根据numa进行顺序绑定
    --tp-size $tp_size
    --pp-size $pp_size
    --trust-remote-code
    --dtype bfloat16
    --port $port
    --attention-backend fa3
    --page-size 64
    --watchdog-timeout 36000
    --kv-cache-dtype fp8_e4m3
    --enable-piecewise-cuda-graph
    --speculative-algorithm EAGLE
    --speculative-num-steps 3
    --speculative-eagle-topk 1
    --speculative-num-draft-tokens 4
    --model-path $model_path
    --host $host_ip
    --mem-fraction-static 0.8
    --disable-radix-cache
    --chunked-prefill-size -1
    --skip-server-warmup
    --cuda-graph-max-bs 64
    --max-running-request 128
)
FINAL_ARGS=("${DEFAULT_ARGS[@]}")
logpath="server/$model-tp$tp_size-dp$dp_size-ep$ep_size-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi


# Print command with formatted arguments (one per line)
printf '%s\n' "python3 -m sglang.launch_server \\"
i=0
while [[ $i -lt ${#FINAL_ARGS[@]} ]]; do
  arg="${FINAL_ARGS[$i]}"
  if [[ "$arg" == --* ]]; then
    next=$((i + 1))
    if [[ $next -lt ${#FINAL_ARGS[@]} && "${FINAL_ARGS[$next]}" != --* ]]; then
      printf ' %s %s \\\n' "$arg" "${FINAL_ARGS[$next]}"
      i=$((i + 2))
    else
      printf ' %s \\\n' "$arg"
      i=$((i + 1))
    fi
  else
    printf ' %s \\\n' "$arg"
    i=$((i + 1))
  fi
done
printf '%s\n' " 2>&1 | tee running_qwen3.5_397b_${the_host}.log"
printf '%s\n' "--------------------------------"
python3 -m sglang.launch_server "${FINAL_ARGS[@]}" 2>&1 | tee $logpath/$time.log

```

#### BMZ

双机,两个节点分别执行

bash 397\_bf16\.sh 0

bash 397\_bf16\.sh 1

```Bash
#!/bin/bash

port=${1:-30005}
model_path=${2:-/model/qwen3.5/Qwen3.5-397B-A17B}
model=${model_path##*/}
the_host=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')

net_ifname=ens47f0np0
export NCCL_SOCKET_IFNAME=ens47f0np0
export GLOO_SOCKET_IFNAME=ens47f0np0
#time
time=$(date "+%m%d-%H%M")


echo "---- Current Env Variables Setup ------"
env_vars=(
    "NCCL_MIN_NCHANNELS=16"
    "NCCL_MAX_NCHANNELS=16"
    "SGLANG_ENABLE_SPEC_V2=1"
    "SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile"
    "HSA_ENABLE_COREDUMP=1"
    "USE_DCU_CUSTOM_ALLREDUCE=1" # default using vllm allreduce, if set to 1, ALLREDUCE_STREAM_WITH_COMPUTE has to be set to 1, optimize for graph mode
    "ALLREDUCE_STREAM_WITH_COMPUTE"
    "HIP_KERNEL_EVENT_SYSTENFENCE=1"       # default using vllm allreduce, optimize for egar mode
    "SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0" # default stay
    "GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000" # default stay
    "HIP_KERNEL_BATCH_CEILING=100"    # default stay
    "GPU_FORCE_BLIT_COPY_SIZE=16"     # default stay
    "HSA_KERNARG_POOL_SIZE=8388608"   # default stay
    "ROC_AQL_QUEUE_SIZE=131072"       # default stay
    "SGLANG_USE_LIGHTOP=1"            # enable lightop rope and topk kernel
#    "SGLANG_USE_FP8_W8A8_MOE=1"       # using lightop fp8 moe kernel
    "SGLANG_USE_MARLIN_W16A16_MOE=1"
    "SGLANG_USE_FUSED_TOPK_SOFTMAX=1" # Specially for topk of Qwen-model and bailing
    "SGLANG_USE_CAUSAL_CONV1D=1"
    # "SGLANG_USE_FUSED_GEMMRMS_QUANT=1"
    # "SGLANG_USE_FUSED_RMS_ROTARY=1"
    "SGLANG_KV_LAYOUT_DCU_FA=1" # default enable, using optimized PA layout
    "SGLANG_USE_AITER_LINEAR_ATTN=1"
)
for kv in "${env_vars[@]}"; do
    export "$kv"
    echo "export $kv"
done

sysctl -w kernel.numa_balancing=0

echo "---- Current Running Cmd ------"
tp_size=16
pp_size=1
dp_size=1
ep_size=1
nodes=2
rank=$1
#master_ip=$host_ip
master_ip=<HOST_IP>
#host_ip=0.0.0.0
DEFAULT_ARGS=(
    --numa-node 0 0 0 0 1 1 1 1     # 根据numa进行顺序绑定
    --tp-size $tp_size
    --pp-size $pp_size
    --trust-remote-code
    --dtype bfloat16
    --port $port
    --attention-backend fa3
    --page-size 64
    --watchdog-timeout 36000
    --kv-cache-dtype fp8_e5m2
    --enable-piecewise-cuda-graph
    --speculative-algorithm EAGLE
    --speculative-num-steps 3
    --speculative-eagle-topk 1
    --speculative-num-draft-tokens 4
    --model-path $model_path
    --host $host_ip
    --mem-fraction-static 0.8
#    --disable-radix-cache
    --mamba-scheduler-strategy extra_buffer
#    --chunked-prefill-size -1
    --skip-server-warmup
    --cuda-graph-max-bs 64
    --max-running-request 48
    --dist-init-addr $master_ip:5000 --nnodes $nodes --node-rank $rank
)
FINAL_ARGS=("${DEFAULT_ARGS[@]}")
logpath="server/$model-tp$tp_size-dp$dp_size-ep$ep_size-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi


# Print command with formatted arguments (one per line)
printf '%s\n' "python3 -m sglang.launch_server \\"
i=0
while [[ $i -lt ${#FINAL_ARGS[@]} ]]; do
  arg="${FINAL_ARGS[$i]}"
  if [[ "$arg" == --* ]]; then
    next=$((i + 1))
    if [[ $next -lt ${#FINAL_ARGS[@]} && "${FINAL_ARGS[$next]}" != --* ]]; then
      printf ' %s %s \\\n' "$arg" "${FINAL_ARGS[$next]}"
      i=$((i + 2))
    else
      printf ' %s \\\n' "$arg"
      i=$((i + 1))
    fi
  else
    printf ' %s \\\n' "$arg"
    i=$((i + 1))
  fi
done
printf '%s\n' " 2>&1 | tee running_qwen3.5_397b_${the_host}.log"
printf '%s\n' "--------------------------------"
python3 -m sglang.launch_server "${FINAL_ARGS[@]}" 2>&1 | tee $logpath/$time.log

```

## Qwen3\.5\-397B\-A17B\-Channel\-FP8

### 测试模式

#### NMZ

```Bash
#!/bin/bash

port=${1:-30005}
model_path=${2:-/model/qwen3.5/Qwen3.5-397B-A17B-Channel-FP8}

the_host=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')

net_ifname=enp9s0f4u1c2
#time
time=$(date "+%m%d-%H%M")


echo "---- Current Env Variables Setup ------"
env_vars=(
    "NCCL_MIN_NCHANNELS=16"
    "NCCL_MAX_NCHANNELS=16"
    "SGLANG_ENABLE_SPEC_V2=1"
    "SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile"
    "HSA_ENABLE_COREDUMP=1"
    "USE_DCU_CUSTOM_ALLREDUCE=1" # default using vllm allreduce, if set to 1, ALLREDUCE_STREAM_WITH_COMPUTE has to be set to 1, optimize for graph mode
    "ALLREDUCE_STREAM_WITH_COMPUTE"
    "HIP_KERNEL_EVENT_SYSTENFENCE=1"       # default using vllm allreduce, optimize for egar mode
    "SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0" # default stay
    "GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000" # default stay
    "HIP_KERNEL_BATCH_CEILING=100"    # default stay
    "GPU_FORCE_BLIT_COPY_SIZE=16"     # default stay
    "HSA_KERNARG_POOL_SIZE=8388608"   # default stay
    "ROC_AQL_QUEUE_SIZE=131072"       # default stay
    "SGLANG_USE_LIGHTOP=1"            # enable lightop rope and topk kernel
    "SGLANG_USE_FP8_W8A8_MOE=1"       # using lightop fp8 moe kernel
    "SGLANG_USE_FUSED_TOPK_SOFTMAX=1" # Specially for topk of Qwen-model and bailing
    "SGLANG_USE_CAUSAL_CONV1D=1"
    # "SGLANG_USE_FUSED_GEMMRMS_QUANT=1"
    # "SGLANG_USE_FUSED_RMS_ROTARY=1"
    "SGLANG_KV_LAYOUT_DCU_FA=1" # default enable, using optimized PA layout
    "SGLANG_USE_AITER_LINEAR_ATTN=1"
)
for kv in "${env_vars[@]}"; do
    export "$kv"
    echo "export $kv"
done

sysctl -w kernel.numa_balancing=0

echo "---- Current Running Cmd ------"
tp_size=4
pp_size=1
dp_size=1
ep_size=1
#host_ip=0.0.0.0
DEFAULT_ARGS=(
    --numa-node 0 0 0 0 1 1 1 1     # 根据numa进行顺序绑定
    --tp-size $tp_size
    --pp-size $pp_size
    --trust-remote-code
    --dtype bfloat16
    --port $port
    --attention-backend fa3
    --page-size 64
    --watchdog-timeout 36000
    --kv-cache-dtype fp8_e4m3
    --enable-piecewise-cuda-graph
    --speculative-algorithm EAGLE
    --speculative-num-steps 3
    --speculative-eagle-topk 1
    --speculative-num-draft-tokens 4
    --model-path $model_path
    --host $host_ip
    --mem-fraction-static 0.8
    --disable-radix-cache
    --chunked-prefill-size -1
    --skip-server-warmup
    --cuda-graph-max-bs 64
)
FINAL_ARGS=("${DEFAULT_ARGS[@]}")
logpath="server/$model-tp$tp_size-dp$dp_size-ep$ep_size-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi


# Print command with formatted arguments (one per line)
printf '%s\n' "python3 -m sglang.launch_server \\"
i=0
while [[ $i -lt ${#FINAL_ARGS[@]} ]]; do
  arg="${FINAL_ARGS[$i]}"
  if [[ "$arg" == --* ]]; then
    next=$((i + 1))
    if [[ $next -lt ${#FINAL_ARGS[@]} && "${FINAL_ARGS[$next]}" != --* ]]; then
      printf ' %s %s \\\n' "$arg" "${FINAL_ARGS[$next]}"
      i=$((i + 2))
    else
      printf ' %s \\\n' "$arg"
      i=$((i + 1))
    fi
  else
    printf ' %s \\\n' "$arg"
    i=$((i + 1))
  fi
done
printf '%s\n' " 2>&1 | tee running_qwen3.5_397b_${the_host}.log"
printf '%s\n' "--------------------------------"
python3 -m sglang.launch_server "${FINAL_ARGS[@]}" 2>&1 | tee $logpath_$time.log

```

#### BW1000

不支持

#### KME

不支持

## Qwen3\.5\-397B\-A17B\-W8A8

#### NMZ

```Bash
#!/bin/bash

port=${1:-30005}
model_path=${2:-/model/qwen3.5/Qwen3.5-397B-A17B-W8A8}

the_host=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#time
time=$(date "+%m%d-%H%M")


echo "---- Current Env Variables Setup ------"
env_vars=(
    "NCCL_MIN_NCHANNELS=16"
    "NCCL_MAX_NCHANNELS=16"
    "SGLANG_ENABLE_SPEC_V2=1"
    "SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile"
    "HSA_ENABLE_COREDUMP=1"
    "USE_DCU_CUSTOM_ALLREDUCE=1" # default using vllm allreduce, if set to 1, ALLREDUCE_STREAM_WITH_COMPUTE has to be set to 1, optimize for graph mode
    "ALLREDUCE_STREAM_WITH_COMPUTE"
    "HIP_KERNEL_EVENT_SYSTENFENCE=1"       # default using vllm allreduce, optimize for egar mode
    "SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0" # default stay
    "GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000" # default stay
    "HIP_KERNEL_BATCH_CEILING=100"    # default stay
    "GPU_FORCE_BLIT_COPY_SIZE=16"     # default stay
    "HSA_KERNARG_POOL_SIZE=8388608"   # default stay
    "ROC_AQL_QUEUE_SIZE=131072"       # default stay
    "SGLANG_USE_LIGHTOP=1"            # enable lightop rope and topk kernel
#    "SGLANG_USE_FP8_W8A8_MOE=1"       # using lightop fp8 moe kernel
    "SGLANG_USE_FUSED_TOPK_SOFTMAX=1" # Specially for topk of Qwen-model and bailing
    "SGLANG_USE_CAUSAL_CONV1D=1"
    # "SGLANG_USE_FUSED_GEMMRMS_QUANT=1"
    # "SGLANG_USE_FUSED_RMS_ROTARY=1"
    "SGLANG_KV_LAYOUT_DCU_FA=1" # default enable, using optimized PA layout
    "SGLANG_USE_AITER_LINEAR_ATTN=1"
)
for kv in "${env_vars[@]}"; do
    export "$kv"
    echo "export $kv"
done

sysctl -w kernel.numa_balancing=0

echo "---- Current Running Cmd ------"
tp_size=4
pp_size=1
dp_size=1
ep_size=1
#host_ip=0.0.0.0
DEFAULT_ARGS=(
    --numa-node 0 0 0 0 1 1 1 1     # 根据numa进行顺序绑定
    --tp-size $tp_size
    --pp-size $pp_size
    --trust-remote-code
    --dtype bfloat16
    --port $port
    --attention-backend fa3
#    --quantization w8a8_int8
    --quantization slimquant_marlin
    --page-size 64
    --watchdog-timeout 36000
    --kv-cache-dtype fp8_e4m3
    --enable-piecewise-cuda-graph
    --speculative-algorithm EAGLE
    --speculative-num-steps 3
    --speculative-eagle-topk 1
    --speculative-num-draft-tokens 4
    --model-path $model_path
    --host $host_ip
    --mem-fraction-static 0.8
＃    --disable-radix-cache
   　--mamba-scheduler-strategy extra_buffer
    --chunked-prefill-size -1
    --skip-server-warmup
    --cuda-graph-max-bs 64
#    --max-running-request 64
)
FINAL_ARGS=("${DEFAULT_ARGS[@]}")
logpath="server/$model-tp$tp_size-dp$dp_size-ep$ep_size-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi


# Print command with formatted arguments (one per line)
printf '%s\n' "python3 -m sglang.launch_server \\"
i=0
while [[ $i -lt ${#FINAL_ARGS[@]} ]]; do
  arg="${FINAL_ARGS[$i]}"
  if [[ "$arg" == --* ]]; then
    next=$((i + 1))
    if [[ $next -lt ${#FINAL_ARGS[@]} && "${FINAL_ARGS[$next]}" != --* ]]; then
      printf ' %s %s \\\n' "$arg" "${FINAL_ARGS[$next]}"
      i=$((i + 2))
    else
      printf ' %s \\\n' "$arg"
      i=$((i + 1))
    fi
  else
    printf ' %s \\\n' "$arg"
    i=$((i + 1))
  fi
done
printf '%s\n' " 2>&1 | tee running_qwen3.5_397b_${the_host}.log"
printf '%s\n' "--------------------------------"
python3 -m sglang.launch_server "${FINAL_ARGS[@]}" 2>&1 | tee $logpath_$time.log

```

#### BW1000

```Bash
#!/bin/bash

port=${1:-30005}
model_path=${2:-/model/qwen3.5/Qwen3.5-397B-A17B-W8A8}

the_host=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')

net_ifname=enp9s0f4u1c2
#time
time=$(date "+%m%d-%H%M")


echo "---- Current Env Variables Setup ------"
env_vars=(
    "NCCL_MIN_NCHANNELS=16"
    "NCCL_MAX_NCHANNELS=16"
    "SGLANG_ENABLE_SPEC_V2=1"
    "SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile"
    "HSA_ENABLE_COREDUMP=1"
    "USE_DCU_CUSTOM_ALLREDUCE=1" # default using vllm allreduce, if set to 1, ALLREDUCE_STREAM_WITH_COMPUTE has to be set to 1, optimize for graph mode
    "ALLREDUCE_STREAM_WITH_COMPUTE"
    "HIP_KERNEL_EVENT_SYSTENFENCE=1"       # default using vllm allreduce, optimize for egar mode
    "SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0" # default stay
    "GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000" # default stay
    "HIP_KERNEL_BATCH_CEILING=100"    # default stay
    "GPU_FORCE_BLIT_COPY_SIZE=16"     # default stay
    "HSA_KERNARG_POOL_SIZE=8388608"   # default stay
    "ROC_AQL_QUEUE_SIZE=131072"       # default stay
    "SGLANG_USE_LIGHTOP=1"            # enable lightop rope and topk kernel
#    "SGLANG_USE_FP8_W8A8_MOE=1"       # using lightop fp8 moe kernel
    "SGLANG_USE_FUSED_TOPK_SOFTMAX=1" # Specially for topk of Qwen-model and bailing
    "SGLANG_USE_CAUSAL_CONV1D=1"
    # "SGLANG_USE_FUSED_GEMMRMS_QUANT=1"
    # "SGLANG_USE_FUSED_RMS_ROTARY=1"
    "SGLANG_KV_LAYOUT_DCU_FA=1" # default enable, using optimized PA layout
    "SGLANG_USE_AITER_LINEAR_ATTN=1"
)
for kv in "${env_vars[@]}"; do
    export "$kv"
    echo "export $kv"
done

sysctl -w kernel.numa_balancing=0

echo "---- Current Running Cmd ------"
tp_size=8
pp_size=1
dp_size=1
ep_size=1
#host_ip=0.0.0.0
DEFAULT_ARGS=(
    --numa-node 0 0 0 0 1 1 1 1     # 根据numa进行顺序绑定
    --tp-size $tp_size
    --pp-size $pp_size
    --trust-remote-code
    --dtype bfloat16
    --port $port
    --attention-backend fa3
#    --quantization w8a8_int8
    --quantization slimquant_marlin
    --page-size 64
    --watchdog-timeout 36000
    --kv-cache-dtype fp8_e5m2
    --enable-piecewise-cuda-graph
    --speculative-algorithm EAGLE
    --speculative-num-steps 3
    --speculative-eagle-topk 1
    --speculative-num-draft-tokens 4
    --model-path $model_path
    --host $host_ip
    --mem-fraction-static 0.85
#    --disable-radix-cache
    --mamba-scheduler-strategy extra_buffer
    --enable-piecewise-cuda-graph
    --chunked-prefill-size -1
    --skip-server-warmup
    --cuda-graph-max-bs 64
#    --max-running-request 64
)
FINAL_ARGS=("${DEFAULT_ARGS[@]}")
logpath="server/$model-tp$tp_size-dp$dp_size-ep$ep_size-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi


# Print command with formatted arguments (one per line)
printf '%s\n' "python3 -m sglang.launch_server \\"
i=0
while [[ $i -lt ${#FINAL_ARGS[@]} ]]; do
  arg="${FINAL_ARGS[$i]}"
  if [[ "$arg" == --* ]]; then
    next=$((i + 1))
    if [[ $next -lt ${#FINAL_ARGS[@]} && "${FINAL_ARGS[$next]}" != --* ]]; then
      printf ' %s %s \\\n' "$arg" "${FINAL_ARGS[$next]}"
      i=$((i + 2))
    else
      printf ' %s \\\n' "$arg"
      i=$((i + 1))
    fi
  else
    printf ' %s \\\n' "$arg"
    i=$((i + 1))
  fi
done
printf '%s\n' " 2>&1 | tee running_qwen3.5_397b_${the_host}.log"
printf '%s\n' "--------------------------------"
python3 -m sglang.launch_server "${FINAL_ARGS[@]}" 2>&1 | tee $logpath_$time.log

```

#### KME

```Bash
#!/bin/bash

port=${1:-30005}
model_path=${2:-/model/qwen3.5/Qwen3.5-397B-A17B-W8A8}
model=${model_path##*/}
the_host=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')

#net_ifname=enp9s0f4u1c2
#time
time=$(date "+%m%d-%H%M")


echo "---- Current Env Variables Setup ------"
env_vars=(
    "NCCL_MIN_NCHANNELS=16"
    "NCCL_MAX_NCHANNELS=16"
    "SGLANG_ENABLE_SPEC_V2=1"
    "SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile"
    "HSA_ENABLE_COREDUMP=1"
    "USE_DCU_CUSTOM_ALLREDUCE=1" # default using vllm allreduce, if set to 1, ALLREDUCE_STREAM_WITH_COMPUTE has to be set to 1, optimize for graph mode
    "ALLREDUCE_STREAM_WITH_COMPUTE"
    "HIP_KERNEL_EVENT_SYSTENFENCE=1"       # default using vllm allreduce, optimize for egar mode
    "SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0" # default stay
    "GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000" # default stay
    "HIP_KERNEL_BATCH_CEILING=100"    # default stay
    "GPU_FORCE_BLIT_COPY_SIZE=16"     # default stay
    "HSA_KERNARG_POOL_SIZE=8388608"   # default stay
    "ROC_AQL_QUEUE_SIZE=131072"       # default stay
    "SGLANG_USE_LIGHTOP=1"            # enable lightop rope and topk kernel
#    "SGLANG_USE_FP8_W8A8_MOE=1"       # using lightop fp8 moe kernel
    "SGLANG_USE_FUSED_TOPK_SOFTMAX=1" # Specially for topk of Qwen-model and bailing
    "SGLANG_USE_CAUSAL_CONV1D=1"
    # "SGLANG_USE_FUSED_GEMMRMS_QUANT=1"
    # "SGLANG_USE_FUSED_RMS_ROTARY=1"
    "SGLANG_KV_LAYOUT_DCU_FA=0" # default enable, using optimized PA layout
    "SGLANG_USE_AITER_LINEAR_ATTN=1"
)
for kv in "${env_vars[@]}"; do
    export "$kv"
    echo "export $kv"
done

sysctl -w kernel.numa_balancing=0

echo "---- Current Running Cmd ------"
tp_size=8
pp_size=1
dp_size=1
ep_size=1
#host_ip=0.0.0.0
DEFAULT_ARGS=(
    --numa-node 0 0 0 0 1 1 1 1     # 根据numa进行顺序绑定
    --tp-size $tp_size
    --pp-size $pp_size
    --trust-remote-code
    --dtype bfloat16
    --port $port
    --attention-backend fa3
    --quantization w8a8_int8
#    --quantization slimquant_marlin
    --page-size 64
    --watchdog-timeout 36000
 #   --kv-cache-dtype fp8_e4m3
    --enable-piecewise-cuda-graph
#    --speculative-algorithm EAGLE
#    --speculative-num-steps 3
#    --speculative-eagle-topk 1
#    --speculative-num-draft-tokens 4
    --model-path $model_path
    --host $host_ip
    --mem-fraction-static 0.85
    --disable-radix-cache
    --chunked-prefill-size -1
    --skip-server-warmup
    --cuda-graph-max-bs 48
#    --max-running-request 256
)
FINAL_ARGS=("${DEFAULT_ARGS[@]}")
logpath="server/$model-tp$tp_size-dp$dp_size-ep$ep_size-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi


# Print command with formatted arguments (one per line)
printf '%s\n' "python3 -m sglang.launch_server \\"
i=0
while [[ $i -lt ${#FINAL_ARGS[@]} ]]; do
  arg="${FINAL_ARGS[$i]}"
  if [[ "$arg" == --* ]]; then
    next=$((i + 1))
    if [[ $next -lt ${#FINAL_ARGS[@]} && "${FINAL_ARGS[$next]}" != --* ]]; then
      printf ' %s %s \\\n' "$arg" "${FINAL_ARGS[$next]}"
      i=$((i + 2))
    else
      printf ' %s \\\n' "$arg"
      i=$((i + 1))
    fi
  else
    printf ' %s \\\n' "$arg"
    i=$((i + 1))
  fi
done
printf '%s\n' " 2>&1 | tee running_qwen3.5_397b_${the_host}.log"
printf '%s\n' "--------------------------------"
python3 -m sglang.launch_server "${FINAL_ARGS[@]}" 2>&1 | tee $logpath/$time.log
```

1 开启radix\-cache,需要添加参数\-\-mamba\-scheduler\-strategy extra\_buffer,精度会有问题

2 使用\-\-quantization slimquant\_marlin会报moe size不支持,[internal-link-removed]

## MiMo\-V2\-Flash

#### NMZ

```SQL
export SGLANG_USE_LIGHTOP=1
export SGLANG_KV_LAYOUT_DCU_FA=0
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_USE_AITER_FP8_ASM_MOE=1
export SGLANG_USE_MODELSCOPE=1
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

log_date=$(date "+%Y-%m-%d")
log_dir="./${log_date}"
if ! mkdir -p "${log_dir}"; then
    exit 1
fi


sglang serve \
    --model-path <LOCAL_PATH> \
    --pp-size 1 \
    --dp-size 2 \
    --tp-size 8 \
    --page-size 64 \
    --host 0.0.0.0 \
    --trust-remote-code \
    --mem-fraction-static 0.85 \
    --max-running-requests 128 \
    --tool-call-parser mimo \
    --disable-radix-cache \
    --context-length 262144 \
    --attention-backend triton \
    --chunked-prefill-size -1 \
    --enable-dp-attention \
    --speculative-algorithm EAGLE \
    --speculative-num-steps 3 \
    --speculative-eagle-topk 1 \
    --speculative-num-draft-tokens 4 \
    2>&1 | tee "${log_dir}/${model}_serve_${time}.log"

```

#### BW1000

不支持此模型

#### KME

不支持此模型

## MiMo\-V2\-Flash\-Channel\-FP8\-w8a8

#### NMZ

```SQL
export SGLANG_USE_LIGHTOP=1
export SGLANG_KV_LAYOUT_DCU_FA=0
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_USE_FP8_W8A8_MOE=1
export SGLANG_USE_MODELSCOPE=1


log_date=$(date "+%Y-%m-%d")
log_dir="./${log_date}"
if ! mkdir -p "${log_dir}"; then
    exit 1
fi

sglang serve \
    --model-path <LOCAL_PATH> \
    --pp-size 1 \
    --dp-size 2 \
    --tp-size 8 \
    --page-size 64 \
    --host 0.0.0.0 \
    --trust-remote-code \
    --mem-fraction-static 0.85 \
    --max-running-requests 128 \
    --tool-call-parser mimo \
    --disable-radix-cache \
    --context-length 262144 \
    --attention-backend triton \
    --chunked-prefill-size -1 \
    --enable-dp-attention \
    --speculative-algorithm EAGLE \
    --speculative-num-steps 3 \
    --speculative-eagle-topk 1 \
    --speculative-num-draft-tokens 4 \
2>&1 | tee "${log_dir}/${model}_serve_${time}.log"
```

#### BW1000

不支持此模型

#### KME

不支持此模型



## MiMo\-V2\-Flash\-Channel\-INT8\-w8a8

#### NMZ

暂无

#### BW1000

```SQL
export HSA_SCRATCH_SINGLE_LIMIT=1073741824
export HSA_NO_SCRATCH_RECLAIM=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_KV_LAYOUT_DCU_FA=0
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_USE_TRITON_EXTEND_FROM_AITER=1
export SGLANG_USE_MODELSCOPE=1

sglang serve \
    --model-path <LOCAL_PATH> \
    --pp-size 1 \
    --dp-size 1 \
    --tp-size 8 \
    --page-size 64 \
    --trust-remote-code \
    --mem-fraction-static 0.75 \
    --quantization slimquant_marlin \
    --max-running-requests 128 \
    --tool-call-parser mimo \
    --context-length 262144 \
    --chunked-prefill-size -1 \
    --disable-radix-cache \
    --port 11010 \
    --attention-backend triton \
    --speculative-algorithm EAGLE \
    --speculative-num-steps 3 \
    --speculative-eagle-topk 1 \
    --speculative-num-draft-tokens 4 \
    2>&1 | tee "${log_dir}/${model}_serve_${time}.log"

```

#### KME

暂无

## Qwen3\-Coder\-480B\-A35B\-Instruct\-FP8\-Dynamic

#### NMZ

暂无

#### BW1000

不支持此模型

#### KME

不支持此模型



## Qwen3\-Coder\-480B\-A35B\-Instruct\-w8a8

#### NMZ

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 1 1 2 2 3 3 "
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option}   --quantization w8a8_int8 \
      --kv-cache-dtype fp8_e4m3  --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log


```

启动：bash server\-sglang\-normal\-bfloat16\.sh  <LOCAL_PATH>  8 30000 5000

#### BW1000

node0：bash server\-sglang\-480b\-w8a8\-tp16\-rank0\.sh  <LOCAL_PATH>  16 30000 5000

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=2

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option}   --quantization w8a8_int8 \
      --kv-cache-dtype fp8_e5m2  --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port  \
    --dist-init-addr <HOST_IP>:5000 --nnodes 2 --node-rank 0 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
```

node1：bash server\-sglang\-480b\-w8a8\-tp16\-rank1\.sh <LOCAL_PATH>  16 30000 5000

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=1
nodes=2

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1"
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option}   --quantization w8a8_int8 \
      --kv-cache-dtype fp8_e5m2  --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port  \
    --dist-init-addr <HOST_IP>:5000 --nnodes 2 --node-rank 1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
```

#### KME

暂无

## Qwen3\-VL\-235B\-A22B\-Instruct

#### NMZ

bash server\-sglang\-vl\-nmz\.sh  <LOCAL_PATH>

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
model_path=$1
model=${model_path##*/}
tp=4
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 1 1 2 2 3 3  "
option+=" --mm-attention-backend fa3"
option+=" --dtype float16"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e4m3  --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
```

#### BW1000

bash server\-sglang\-vl\.sh <LOCAL_PATH>

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
model_path=$1
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype float16"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e5m2  --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

#### KME

暂无

```Plain Text

```



## Qwen3\-30B\-A3B\-bf16

#### NMZ

bash server\-sglang\-normal\.sh  <LOCAL_PATH>  1 30000 5000

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
export HIP_VISIBLE_DEVICES=5

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype float16"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e4m3  --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log


```

#### BW1000

bash server\-sglang\-normal\.sh  <LOCAL_PATH>  2 30000 5000

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
export HIP_VISIBLE_DEVICES=5

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype float16"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e5m2  --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
```

#### KME

暂无

## Qwen3\-30B\-A3B\-w8a8

#### NMZ

bash server\-sglang\-normal\-bfloat16\-qwen3\-30b\-w8a8\.sh  <LOCAL_PATH>  1 30001 5001

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=0

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option}   --quantization w8a8_int8 \
      --kv-cache-dtype fp8_e4m3 --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

#### BW1000

bash server\-sglang\-normal\-bfloat16\-qwen3\-30b\-w8a8\.sh  <LOCAL_PATH>  1 30001 5001

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=0

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option}   --quantization w8a8_int8 \
      --kv-cache-dtype fp8_e5m2 --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```



#### KME

bash server\-sglang\-normal\-bfloat16\-qwen3\-30b\-w8a8\.sh  <LOCAL_PATH>  1 30001 5001

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=0
model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype bfloat16"
sglang serve --model-path $model_path --trust-remote-code  ${option}   --quantization w8a8_int8 \
      --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```



## DeepSeek\-R1\-Distill\-Llama\-70B

### 测试模式

### NMZ

```Bash
export NODE2_IP="<HOST_IP>"  #按照实际
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
# export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export NCCL_IB_HCA=mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9, #按照实际
export NCCL_SOCKET_IFNAME=ens19f0 #按照实际
export GLOO_SOCKET_IFNAME=ens19f0 #按照实际
export NCCL_IB_GID_INDEX=3
# export GPU_FLUSH_ON_EXECUTION=1 #调试专用

time=$(date "+%Y-%m-%d-%H-%M-%S")
model_test=DeepSeek-R1-Distill-Llama-70B-main--1.4
log_date=$(date "+%Y-%m-%d")
log_dir="./NMZ/NMZ_${model_test}/${log_date}"
mkdir -p "${log_dir}"

sglang serve \
  --model-path /model/deepseek-r1/DeepSeek-R1-Distill-Llama-70B-main \
  --trust-remote-code \
  --tp-size 8 \
  --attention-backend fa3 \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype fp8_e4m3 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
   2>&1 | tee "${log_dir}/serve_${time}.log"
```

### bmz

```Bash

export NODE2_IP="<HOST_IP>"
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
# export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export NCCL_IB_HCA=mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9, #按照实际
export NCCL_SOCKET_IFNAME=ens24f0 #按照实际
export GLOO_SOCKET_IFNAME=ens24f0 #按照实际
export NCCL_IB_GID_INDEX=3
# export SGLANG_USE_AITER=1
# export GPU_FLUSH_ON_EXECUTION=1 #调试专用

time=$(date "+%Y-%m-%d-%H-%M-%S")
model_test=DeepSeek-R1-Distill-Llama-70B-main
log_date=$(date "+%Y-%m-%d")
log_dir="./BMZ/BMZ_${model_test}/${log_date}"
mkdir -p "${log_dir}"

sglang serve \
  --model-path /model/deepseek-r1/DeepSeek-R1-Distill-Llama-70B-main \
  --trust-remote-code \
  --tp-size 8 \
  --attention-backend fa3 \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype fp8_e5m2 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
  2>&1 | tee "${log_dir}/serve_${time}.log"
```

### K100

```Bash

export NODE2_IP="<HOST_IP>"
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
# export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
#export NCCL_IB_HCA=mlx5_0  #按照实际
export NCCL_SOCKET_IFNAME=ens8f0 #按照实际
export GLOO_SOCKET_IFNAME=ens8f0 #按照实际
export NCCL_IB_GID_INDEX=3
# export SGLANG_USE_AITER=1
# export GPU_FLUSH_ON_EXECUTION=1 #调试专用

time=$(date "+%Y-%m-%d-%H-%M-%S")
model_test=DeepSeek-R1-Distill-Llama-70B-main
log_date=$(date "+%Y-%m-%d")
log_dir="./K100_AI/K100_AI_${model_test}/${log_date}"
mkdir -p "${log_dir}"

sglang serve \
  --model-path /model/deepseek-r1/DeepSeek-R1-Distill-Llama-70B-main \
  --trust-remote-code \
  --tp-size 4 \
  --attention-backend fa3 \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype bf16 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
  2>&1 | tee "${log_dir}/serve_${time}.log"
```

## DeepSeek\-R1\-Distill\-Llama\-70B\-int8

### 测试模式

```Plain Text

```

#### NMZ

```Bash
export NODE2_IP="<HOST_IP>" #按照实际
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
# export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export NCCL_IB_HCA=mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9,#按照实际
export NCCL_SOCKET_IFNAME=ens19f0 #按照实际
export GLOO_SOCKET_IFNAME=ens19f0 #按照实际
export NCCL_IB_GID_INDEX=3
# export GPU_FLUSH_ON_EXECUTION=1 #调试专用
export HIP_VISIBLE_DEVICES=6,7



sglang serve \
  --model-path /model/vllm-w8a8-models/DeepSeek-R1-Distill-Llama-70B-quantized.w8a8  \
  --trust-remote-code \
  --tp-size 2 \
  --attention-backend fa3 \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype fp8_e4m3 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
  --quantization slimquant_marlin
```

#### BMZ

```Bash

export NODE2_IP="<HOST_IP>" #按照实际
export NCCL_MIN_NCHANNELS=16
export NCCL_MAX_NCHANNELS=16
# export SGLANG_ENABLE_SPEC_V2=1
export HSA_ENABLE_COREDUMP=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export HIP_KERNEL_EVENT_SYSTENFENCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_KERNEL_BATCH_CEILING=100
export GPU_FORCE_BLIT_COPY_SIZE=16
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export SGLANG_USE_LIGHTOP=1
export SGLANG_ROCM_USE_AITER_MOE=0
export W8A8_SUPPORT_METHODS=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_GRAPH_ACCUMULATE_DISPATCH=1
export HIP_GRAPH_USE_CMD_CACHE=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export NCCL_IB_HCA=mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_8,mlx5_9 #按照实际
export NCCL_SOCKET_IFNAME=ens19f0 #按照实际
export GLOO_SOCKET_IFNAME=ens19f0 #按照实际
export NCCL_IB_GID_INDEX=3
# export SGLANG_USE_AITER=1
# export GPU_FLUSH_ON_EXECUTION=1 #调试专用


sglang serve \
  --model-path /model/vllm-w8a8-models/DeepSeek-R1-Distill-Llama-70B-quantized.w8a8 \
  --trust-remote-code \
  --tp-size 4 \
  --attention-backend fa3 \
  --dtype bfloat16 \
  --dist-timeout 10000 \
  --watchdog-timeout 3600 \
  --page-size 64 \
  --kv-cache-dtype fp8_e5m2 \
  --mem-fraction-static 0.8 \
  --chunked-prefill-size 8192 \
  --quantization slimquant_marlin
```

#### K100

## Qwen3\.5\-27B

### 测试模式

```SQL
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_USE_FUSED_TOPK_SOFTMAX=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_CAUSAL_CONV1D=1
export SGLANG_USE_AITER_LINEAR_ATTN=1
export SGLANG_USE_MODELSCOPE=1

sglang serve --model-path Qwen/Qwen3.5-27B \
    --attention-backend fa3 \
    --mm-attention-backend fa3 \
    --speculative-algorithm EAGLE \
    --speculative-num-steps 3 \
    --speculative-eagle-topk 1 \
    --speculative-num-draft-tokens 4 \
    --pp-size 1 \
    --page-size 64  \
    --mamba-scheduler-strategy extra_buffer \
    --trust-remote-code \
    --chunked-prefill-size -1
```

### nmz

```Plain Text
-tp-size 2
--kv-cache-dtype fp8_e4m3  (正在复测对比该参数带不带的效果)
```

### BMZ

```Plain Text
-tp-size 4
--kv-cache-dtype fp8_e5m2 (正在复测对比该参数带不带的效果)
```

### K100

```Plain Text
已提bug，带复测
```

## Qwen3\.6\-27B

该模型客户端老断开，github上带有\-\-chunked\-prefill\-size \-1 参数

### 测试模式

```SQL
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_USE_FUSED_TOPK_SOFTMAX=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_CAUSAL_CONV1D=1
export SGLANG_USE_AITER_LINEAR_ATTN=1

sglang serve --model-path Qwen/Qwen3.6-27B \
    --attention-backend fa3 \
    --mm-attention-backend fa3 \
    --speculative-algorithm EAGLE \
    --speculative-num-steps 3 \
    --speculative-eagle-topk 1 \
    --speculative-num-draft-tokens 4 \
    --tp-size 2 --pp-size 1 \
    --page-size 64 \
    --mamba-scheduler-strategy extra_buffer \
    --kv-cache-dtype fp8_e4m3 \
    --trust-remote-code

```

#### NMZ

```Plain Text
--tp-size 2
--kv-cache-dtype fp8_e4m3 (正在复测对比该参数带不带的效果)
```

#### BMZ

```Plain Text
--tp-size 2
--kv-cache-dtype fp8_e5m2 (正在复测对比该参数带不带的效果)
```

#### K100

```Plain Text
待测试
```

## Qwen3\.6\-27B\-W8A8

### 测试模式

```Plain Text

export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_USE_FUSED_TOPK_SOFTMAX=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_CAUSAL_CONV1D=1
export SGLANG_USE_AITER_LINEAR_ATTN=1
export HIP_VISIBLE_DEVICES=6,7
sglang serve --model-path <LOCAL_PATH> \
    --attention-backend fa3 \
    --port 31036 \
    --mm-attention-backend fa3 \
    --speculative-algorithm EAGLE \
    --speculative-num-steps 3 \
    --speculative-eagle-topk 1 \
    --speculative-num-draft-tokens 4 \
    --tp-size 1 --pp-size 1 \
    --page-size 64 \
    --mamba-scheduler-strategy extra_buffer \
    --kv-cache-dtype fp8_e4m3 \
    --trust-remote-code \
    --chunked-prefill-size -1
```

#### NMZ

```Plain Text

```

#### BMZ

```Plain Text

```

#### K100

```Plain Text

```

## Qwen3\-235b\-a22b\-instruct\-2507

### 测试指导

```Bash
python -m sglang.launch_server \
    --model-path /model/qwen3/Qwen3-235B-A22B-Instruct-2507\
    --tp-size 8 \
    --trust-remote-code \
   --attention-backend fa3 \
   --page-size 64
```

#### NMZ

```Plain Text
--mem-fraction-static 0.85\
```

#### BMZ

```Plain Text
--mem-fraction-static 0.9\
```

#### K100

```Plain Text
--mem-fraction-static 0.9 \
```

## Qwen3\-4B\-Thinking\-2507

### 测试模式

```SQL
python -m sglang.launch_server \
    --model-path /model/qwen3/Qwen3-4B-Thinking-2507\
    --tp-size 1 \
    --port 31011 \
    --trust-remote-code \
    --mem-fraction-static 0.85\
   --attention-backend fa3 \
   --page-size 64 \
   2>&1 | tee "${log_dir}/serve_${time}.log"
```

#### NMZ

```Plain Text
同测试模式
```

#### BMZ

```Plain Text
同测试模式
```

#### K100

```Plain Text
同测试模式
```

## DeepSeek\-R1\-Channel\-INT8

### 测试模式

#### NMZ

```Bash
#export SGLANG_KV_LAYOUT_DCU_FA=0
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1 # lmslim需要 vllm
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile

export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1
# export SGLANG_USE_FUSED_MLA_CAT=1
#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
#export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
#export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
#export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
#export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
#export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
#export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
#export SGLANG_USE_FA_FP8=1
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hipGraphLaunch
#export HSA_KERNARG_POOL_SIZE=8388608
#export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model3/vllm-w8a8-models/DeepSeek-R1-Channel-INT8/DeepSeek-R1-Channel-INT8
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
nodes=1
rank=0
host_ip=$(hostname -I | awk '{print $1}')
# host_ip=0.0.0.0
port=30000
hostname=$(hostname)
master_ip=$host_ip
max_model_len=40960
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --disable-radix-cache "
option+=" --chunked-prefill-size -1"
option+=" --max-running-requests 512 "
option+=" --context-length $max_model_len"

option+=" --speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 2  --cuda-graph-max-bs 512"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e4m3 \
                                --host $host_ip  --port $port --trust-remote-code  \
                                --dist-init-addr $master_ip:5001 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log

```

#### BW1000

```Bash
#export SGLANG_KV_LAYOUT_DCU_FA=0
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1 # lmslim需要 vllm
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile

export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1
# export SGLANG_USE_FUSED_MLA_CAT=1
#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
#export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
#export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
#export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
#export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
#export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
#export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
#export SGLANG_USE_FA_FP8=1
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hipGraphLaunch
#export HSA_KERNARG_POOL_SIZE=8388608
#export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model3/vllm-w8a8-models/DeepSeek-R1-Channel-INT8/DeepSeek-R1-Channel-INT8
model=${model_path##*/}
tp=16
pp=1
dp=1
ep=1
nodes=2
rank=0
host_ip=$(hostname -I | awk '{print $1}')
# host_ip=0.0.0.0
port=30000
hostname=$(hostname)
master_ip=$host_ip
max_model_len=32768
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --disable-radix-cache "
option+=" --chunked-prefill-size -1"
option+=" --max-running-requests 32 "
option+=" --context-length $max_model_len"

option+=" --speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 2  --cuda-graph-max-bs 32"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e5m2 \
                                --host $host_ip  --port $port --trust-remote-code  \
                                --dist-init-addr <HOST_IP>:5002 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log

```



```Bash
#export SGLANG_KV_LAYOUT_DCU_FA=0
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1 # lmslim需要 vllm
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile

export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1
# export SGLANG_USE_FUSED_MLA_CAT=1
#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
#export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
#export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
#export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
#export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
#export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
#export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
#export SGLANG_USE_FA_FP8=1
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hipGraphLaunch
#export HSA_KERNARG_POOL_SIZE=8388608
#export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model3/vllm-w8a8-models/DeepSeek-R1-Channel-INT8/DeepSeek-R1-Channel-INT8
model=${model_path##*/}
tp=16
pp=1
dp=1
ep=1
nodes=2
rank=1
host_ip=$(hostname -I | awk '{print $1}')
# host_ip=0.0.0.0
port=30000
hostname=$(hostname)
master_ip=$host_ip
max_model_len=32768
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --disable-radix-cache "
option+=" --chunked-prefill-size -1"
option+=" --max-running-requests 32 "
option+=" --context-length $max_model_len"

option+=" --speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 2  --cuda-graph-max-bs 32"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e5m2 \
                                --host $host_ip  --port $port --trust-remote-code  \
                                --dist-init-addr <HOST_IP>:5002 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log

```

## DeepSeek\-R1\-Channel\-FP8

### 测试模式

#### NMZ

```Shell
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FP8_W8A8_MOE=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT_PATH=1
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=4
export SGLANG_ENABLE_SPEC_V2=1

export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）

export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export USE_SPE_MQP=1
export MC_ALLOWED_IBV_DEVICES=mlx5_6,mlx5_7,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_8,mlx5_9

python3 -m sglang.launch_server \
    --model-path /model/vllm-fp8-models/DeepSeek-R1-Channel-FP8 \
    --numa-node 0 0 0 0 1 1 1 1 \
    --disable-radix-cache \
    --chunked-prefill-size -1 \
    --max-running-requests 256 \
    --speculative-algorithm EAGLE --speculative-num-steps 2  --speculative-eagle-topk 1  --speculative-num-draft-tokens 1 \
    --context-length 65536 \
    --quantization w8a8_fp8 \
    --kv-cache-dtype fp8_e4m3 \
    --host $(hostname -I | awk '{print $1}') \
    --trust-remote-code \
    --dist-init-addr $(hostname -I | awk '{print $1}'):5003 \
    --nnodes 1 \
    --node-rank 0 \
    --dtype bfloat16 \
    --tp-size 8 \
    --pp-size 1 \
    --mem-fraction-static 0.9 \
    --attention-backend dcu_mla

```

## Qwen3\-VL\-30B\-A3B\-Thinking

### 测试模式

#### NMZ

fp8\_e4m3

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
# export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1  # 大ep下无效
# export SGLANG_USE_OPT_CAT=1  # 性能优化版q cat
# export SGLANG_USE_FUSED_MLA_CAT=1  # q cat融入mla，不再需要上一条
# export SGLANG_USE_FUSED_RMSNORM_ROPE=1  # rms+rope+set_kv_buffer融合，融合后可去掉k cat，与上一条可搭配
# export SGLANG_USE_FUSED_RMS_QUANT=1
# export USE_FUSED_RMS_QUANT=1  # lmslim and vllm
# export SGLANG_USE_FUSED_SILU_MUL_QUANT=1  # w8a8下未适配
# export SGLANG_USE_RMS_QUANT_PATH=1
# export SGLANG_USE_FUSED_BAILING_RMS_QUANT=1
# export SGLANG_USE_FUSED_BAILING_SILU_MUL_FP8_QUANT=1
# export SGLANG_USE_FUSED_BAILING_RMS_ROTARY=1
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

model_path=/model/qwen3/Qwen3-VL-30B-A3B-Thinking
#model_path=/model/qwen2.5/Qwen2.5-VL-72B-Instruct
#model_path=$1
model=${model_path##*/}
export HIP_VISIBLE_DEVICES=0
tp=1
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"
#option+=" --disable-radix-cache "
#option+=" --chunked-prefill-size 16384"
#option+=" --max-running-requests 360 "
#option+=" --context-length $max_model_len "
#option+=" --disable-cuda-graph "
#option+=" --chunked-prefill-size -1"
#export SGLANG_PP_LAYER_PARTITION="16,15,15,15"
#export SGLANG_PP_LAYER_PARTITION="10,8,7,7,8,7,7,7"
#option+=" --moe-dense-tp-size 1 "
#option+=" --ep-size $ep "
#option+=" --dp-size $dp --enable-dp-attention --moe-dense-tp-size 1 --enable-dp-lm-head "
# option+=" --speculative-algorithm EAGLE --speculative-num-steps 2  --speculative-eagle-topk 1  --speculative-num-draft-tokens 1 --enable-beta-spec --cuda-graph-max-bs 32 "
#option+=" --enable-torch-compile --torch-compile-max-bs 64"
#option+=" --pp-max-micro-batch-size 4"
#option+=" --schedule-conservativeness 0.3"
#option+=" --disaggregation-decode-dp 8 --disaggregation-decode-tp 8"
#option+=" --disaggregation-ib-device mlx5_9"
    #--speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 1 \
#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off --moe-a2a-backend deepep  --deepep-mode low_latency  --chunked-prefill-size 8192 --max-prefill-tokens 8192
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e4m3  --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

#### BW1000

fp8\_e5m2精度有问题，关闭kvcache量化测试

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
# export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1  # 大ep下无效
# export SGLANG_USE_OPT_CAT=1  # 性能优化版q cat
# export SGLANG_USE_FUSED_MLA_CAT=1  # q cat融入mla，不再需要上一条
# export SGLANG_USE_FUSED_RMSNORM_ROPE=1  # rms+rope+set_kv_buffer融合，融合后可去掉k cat，与上一条可搭配
# export SGLANG_USE_FUSED_RMS_QUANT=1
# export USE_FUSED_RMS_QUANT=1  # lmslim and vllm
# export SGLANG_USE_FUSED_SILU_MUL_QUANT=1  # w8a8下未适配
# export SGLANG_USE_RMS_QUANT_PATH=1
# export SGLANG_USE_FUSED_BAILING_RMS_QUANT=1
# export SGLANG_USE_FUSED_BAILING_SILU_MUL_FP8_QUANT=1
# export SGLANG_USE_FUSED_BAILING_RMS_ROTARY=1
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

model_path=/model/qwen3/Qwen3-VL-30B-A3B-Thinking
#model_path=/model/qwen2.5/Qwen2.5-VL-72B-Instruct
#model_path=$1
model=${model_path##*/}
export HIP_VISIBLE_DEVICES=2,3
tp=2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"
#option+=" --disable-radix-cache "
#option+=" --chunked-prefill-size 16384"
#option+=" --max-running-requests 360 "
#option+=" --context-length $max_model_len "
#option+=" --disable-cuda-graph "
#option+=" --chunked-prefill-size -1"
#export SGLANG_PP_LAYER_PARTITION="16,15,15,15"
#export SGLANG_PP_LAYER_PARTITION="10,8,7,7,8,7,7,7"
#option+=" --moe-dense-tp-size 1 "
#option+=" --ep-size $ep "
#option+=" --dp-size $dp --enable-dp-attention --moe-dense-tp-size 1 --enable-dp-lm-head "
# option+=" --speculative-algorithm EAGLE --speculative-num-steps 2  --speculative-eagle-topk 1  --speculative-num-draft-tokens 1 --enable-beta-spec --cuda-graph-max-bs 32 "
#option+=" --enable-torch-compile --torch-compile-max-bs 64"
#option+=" --pp-max-micro-batch-size 4"
#option+=" --schedule-conservativeness 0.3"
#option+=" --disaggregation-decode-dp 8 --disaggregation-decode-tp 8"
#option+=" --disaggregation-ib-device mlx5_9"
    #--speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 1 \
#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off --moe-a2a-backend deepep  --deepep-mode low_latency  --chunked-prefill-size 8192 --max-prefill-tokens 8192
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

#### KME

fa3精度有问题

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
# export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1  # 大ep下无效
# export SGLANG_USE_OPT_CAT=1  # 性能优化版q cat
# export SGLANG_USE_FUSED_MLA_CAT=1  # q cat融入mla，不再需要上一条
# export SGLANG_USE_FUSED_RMSNORM_ROPE=1  # rms+rope+set_kv_buffer融合，融合后可去掉k cat，与上一条可搭配
# export SGLANG_USE_FUSED_RMS_QUANT=1
# export USE_FUSED_RMS_QUANT=1  # lmslim and vllm
# export SGLANG_USE_FUSED_SILU_MUL_QUANT=1  # w8a8下未适配
# export SGLANG_USE_RMS_QUANT_PATH=1
# export SGLANG_USE_FUSED_BAILING_RMS_QUANT=1
# export SGLANG_USE_FUSED_BAILING_SILU_MUL_FP8_QUANT=1
# export SGLANG_USE_FUSED_BAILING_RMS_ROTARY=1
#export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

model_path=/model/qwen3/Qwen3-VL-30B-A3B-Thinking
#model_path=/model/qwen2.5/Qwen2.5-VL-72B-Instruct
#model_path=$1
model=${model_path##*/}
export HIP_VISIBLE_DEVICES=4,5
export SGLANG_KV_LAYOUT_DCU_FA=0
tp=2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
#option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend triton --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

## DeepSeek\-R1\-Distill\-Qwen\-32B

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1


export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
export HIP_VISIBLE_DEVICES=2,3

model_path=$1
model=${model_path##*/}
tp=${2:-4}
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath='/tmp/sglang_logs/$model-tp$tp-dp$dp-ep$ep-$(hostname)'
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=${3:-30000}
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --kv-cache-dtype fp8_e4m3  --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port \
    --mamba-scheduler-strategy extra_buffer --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
export HIP_VISIBLE_DEVICES=0,1,2,3
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1


export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="/tmp/sglang_logs/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype bfloat16"
option+=" --mamba-scheduler-strategy extra_buffer"
option+=" --quantization w8a8_int8"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
    --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Qwen3\-Next\-80B\-A3B\-Instruct

### 测试模式

```Bash
export HIP_VISIBLE_DEVICES=4,5,6,7
option+=" --mamba-scheduler-strategy extra_buffer"
option+=" --chunked-prefill-size -1"
option+=" --cuda-graph-max-bs 256"
host_ip=$(hostname -I | awk '{print $1}')
# ==========================================
model_path=/model/qwen3/Qwen3-Next-80B-A3B-Instruct
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_FUSED_TOPK_SOFTMAX=1
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_USE_MARLIN_W16A16_MOE=1
#export SGLANG_ROCM_USE_AITER_MOE=False
python3 -u -m sglang.launch_server  ${option} \
  --model-path  $model_path \
  --host $host_ip \
  --port 30003 \
  --tp-size 4  --pp-size 1 \
  --attention-backend fa3 \
  --page-size 64 --pp-size 1  \
  --mem-fraction-static 0.8

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## QwQ\-32B

### 测试模式

```Bash
export HIP_VISIBLE_DEVICES=4,5,6,7
#option="--numa-node 3 1 1 0 7 5 5 4"
option+=" --disable-radix-cache "
#option+=" --mamba-scheduler-strategy extra_buffer"
option+=" --chunked-prefill-size -1"
option+=" --cuda-graph-max-bs 256"
host_ip=$(hostname -I | awk '{print $1}')
# ==========================================
model_path="<LOCAL_PATH>"
# 使用融合算子
export SGLANG_USE_FUSED_SPLIT_QKV_RMS_ROTARY_EMBEDDING=1
python3 -u -m sglang.launch_server  ${option} \
  --model-path  $model_path \
  --host $host_ip \
  --port 3008 \
  --tp-size 4  --pp-size 1 \
  --attention-backend fa3 \
  --page-size 64 --pp-size 1  \
  --mem-fraction-static 0.8
```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Qwen3\-235B\-A22B\-W8A8

### 测试模式

```Bash
export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
python -m sglang.launch_server \
    --model-path /model/vllm-w8a8-models/Qwen3-235B-A22B-W8A8 \
    --tp-size 8 \
    --quantization slimquant_marlin \
    --attention-backend fa3 --page-size 64 \
    --trust-remote-code \
    --mem-fraction-static 0.95

```

### NMZ

```Bash
同测试模式
```

### BW1000

```Bash
同测试模式
```

### KME

```Plain Text
待测试
```

## Qwen3\-VL\-4B\-Instruct

### 测试模式

```Bash
#!/bin/bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）

#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
# export SGLANG_KV_LAYOUT_DCU_FA=0
# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export HIP_VISIBLE_DEVICES=0,1,2,3

model_path="/model/qwen3/Qwen3-VL-4B-Instruct"

option+=" --mm-attention-backend triton_attn"
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
    --tensor-parallel-size 4  \
    --page-size 64 --mm-attention-backend fa3    --attention-backend fa3 --kv-cache-dtype bf16\
    --mem-fraction-static 0.9 \
    2>&1 | tee  qwenvl-4b.log

```

### NMZ

```Bash
同测试模式
```

### BW1000

```Bash
同测试模式
```

### KME

```Bash
同测试模式
```



## Qwen2\.5\-VL\-72B\-Instruct\-quantized\.w8a8

### 测试模式

```Bash
export HIP_VISIBLE_DEVICES=6,7

export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要


model_path=/model/vllm-w8a8-models/Qwen2.5-VL-72B-Instruct-quantized.w8a8/
model=${model_path##*/}
tp=2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30007
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
      --mem-fraction-static $gpu_mem --attention-backend fa3 \
      --host $host_ip  --port $port --dist-init-addr $master_ip:5006 2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试
```

## GLM\-4\-32B\-0414

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

export HIP_VISIBLE_DEVICES=4

model_path=/model/glm4/GLM-4-32B-0414/
model=${model_path##*/}
tp=1
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=2300
port1=2301
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 1 1 2 2 3 3"
option+=" --dtype bfloat16"

# --kv-cache-dtype fp8_e4m3
sglang serve --model-path $model_path --trust-remote-code  ${option} \
    --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试
```

## deepseek\-v3\.1\-terminus

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FP8_W8A8_MOE=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT_PATH=1
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=4
export SGLANG_ENABLE_SPEC_V2=1

export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）

export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export USE_SPE_MQP=1
export MC_ALLOWED_IBV_DEVICES=mlx5_6,mlx5_7,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_8,mlx5_9

python3 -m sglang.launch_server \
    --model-path /model/deepseek-v3.1/DeepSeek-V3.1-Terminus-Channel-FP8/ \
    --numa-node 0 0 0 0 1 1 1 1 \
    --disable-radix-cache \
    --chunked-prefill-size -1 \
    --max-running-requests 256 \
    --speculative-algorithm EAGLE --speculative-num-steps 2  --speculative-eagle-topk 1  --speculative-num-draft-tokens 1 \
    --context-length 65536 \
    --host $(hostname -I | awk '{print $1}') \
    --trust-remote-code \
    --dist-init-addr $(hostname -I | awk '{print $1}'):5003 \
    --nnodes 1 \
    --node-rank 0 \
    --dtype bfloat16 \
    --tp-size 8 \
    --pp-size 1 \
    --mem-fraction-static 0.9 \
    --attention-backend dcu_mla 2>&1 | tee  server/dpsk.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
不支持
```

### KME

```Plain Text
不支持
```

## DeepSeek\-R1\-0528\-W4A8\-V2

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0
#mtp
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1
# export SGLANG_USE_FUSED_MLA_CAT=1
#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）

export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hipGraphLaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
#export W8A8_SUPPORT_METHODS=1
export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/model/vllm-w8a8-models/DeepSeek-R1-0528-W4A8-V2/
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
nodes=1
rank=0
host_ip=$(hostname -I | awk '{print $1}')
host_ip=0.0.0.0
hostname=$(hostname)
master_ip=$host_ip
max_model_len=40960
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"


if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
sglang serve --model-path $model_path ${option}  \
                                --quantization slimquant_w4a8_marlin  \
                                --host $host_ip  --port 30000 --trust-remote-code  \
                                --dist-init-addr $master_ip:5000 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
server启动报错
```

## DeepSeek\-V3\-0324

### NMZ

```Bash
#export SGLANG_KV_LAYOUT_DCU_FA=0
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1 # lmslim需要 vllm
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile

export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1

export SGLANG_USE_FUSED_RMSNORM_ROPE=1


export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/mnt4/DeepSeek-V3-0324-Channel-INT8/
model=${model_path##*/}
tp=8
pp=1
dp=1
ep=1
nodes=1
rank=0
host_ip=$(hostname -I | awk '{print $1}')
# host_ip=0.0.0.0
port=30008
hostname=$(hostname)
master_ip=$host_ip
max_model_len=32768
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --disable-radix-cache "
option+=" --chunked-prefill-size -1"
option+=" --max-running-requests 32 "
option+=" --context-length $max_model_len"

option+=" --speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 2  --cuda-graph-max-bs 32"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e4m3 \
                                --host $host_ip  --port $port --trust-remote-code  \
                                --dist-init-addr <HOST_IP>:5017 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log
```

### BW1000

```Bash
#export SGLANG_KV_LAYOUT_DCU_FA=0
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1 # lmslim需要 vllm
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile

export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1

export SGLANG_USE_FUSED_RMSNORM_ROPE=1


export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/mnt4/DeepSeek-V3-0324-Channel-INT8/
model=${model_path##*/}
tp=16
pp=1
dp=1
ep=1
nodes=2
rank=0
host_ip=$(hostname -I | awk '{print $1}')
# host_ip=0.0.0.0
port=30008
hostname=$(hostname)
master_ip=$host_ip
max_model_len=32768
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --disable-radix-cache "
option+=" --chunked-prefill-size -1"
option+=" --max-running-requests 32 "
option+=" --context-length $max_model_len"

option+=" --speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 2  --cuda-graph-max-bs 32"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e5m2 \
                                --host $host_ip  --port $port --trust-remote-code  \
                                --dist-init-addr <HOST_IP>:5017 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log

```



```Bash
#export SGLANG_KV_LAYOUT_DCU_FA=0
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_LIGHTOP_MOE_SUM_MUL_ADD=1
export SGLANG_USE_OPT_CAT=1
export SGLANG_USE_FUSED_RMS_QUANT=1
export SGLANG_USE_RMS_QUANT_PATH=1
export USE_FUSED_RMS_QUANT=1 # lmslim需要 vllm
export SGLANG_USE_FUSED_SILU_MUL_QUANT=1
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile

export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export SGLANG_ENABLE_SPEC_V2=1

export SGLANG_USE_FUSED_RMSNORM_ROPE=1


export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16

export ALLREDUCE_STREAM_WITH_COMPUTE=1

model_path=/mnt4/DeepSeek-V3-0324-Channel-INT8/
model=${model_path##*/}
tp=16
pp=1
dp=1
ep=1
nodes=2
rank=1
host_ip=$(hostname -I | awk '{print $1}')
# host_ip=0.0.0.0
port=30008
hostname=$(hostname)
master_ip=$host_ip
max_model_len=32768
gpu_mem=0.9
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$hostname"

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --disable-radix-cache "
option+=" --chunked-prefill-size -1"
option+=" --max-running-requests 32 "
option+=" --context-length $max_model_len"

option+=" --speculative-algorithm EAGLE --speculative-num-steps 1  --speculative-eagle-topk 1  --speculative-num-draft-tokens 2  --cuda-graph-max-bs 32"

#SGLANG_HIP_PROF=1 hipprof --hip-trace --trace-off
python3 -m sglang.launch_server --model-path $model_path ${option}  \
                                --quantization slimquant_marlin --kv-cache-dtype fp8_e5m2 \
                                --host $host_ip  --port $port --trust-remote-code  \
                                --dist-init-addr <HOST_IP>:5017 --nnodes $nodes --node-rank $rank \
                                --dtype bfloat16  --tp-size $tp --pp-size $pp \
                                --mem-fraction-static $gpu_mem --attention-backend dcu_mla 2>&1 | tee  ${logpath}-$time.log

```

### KME





## Qwen3\.5\-122B\-A10B

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 3 1 1 0 7 5 5 4 "
option+=" --dtype bfloat16"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
    --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Qwen3\-8B

### 测试模式

```Bash
#!/bin/bash
set -euo pipefail

export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_H2D_DISABLE_COPY_BUFFER=0
export HIP_D2H_DISABLE_COPY_BUFFER=0
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768
export HIP_D2H_DIRECT_COPY_THRESHOLD=512
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_MARLIN_W16A16_MOE=1
export HIP_VISIBLE_DEVICES=6
export CUDA_VISIBLE_DEVICES=6

sysctl -w kernel.numa_balancing=0 || true

model_path=/model/qwen3/Qwen3-8B
host_ip=<HOST_IP>

cd /tmp/sglang_runtime
mkdir -p server

sglang serve --model-path "${model_path}" --trust-remote-code \
  --numa-node 0 0 1 1 2 2 3 3 \
  --dtype bfloat16 \
  --tensor-parallel-size 1 \
  --page-size 64 \
  --mem-fraction-static 0.9 \
  --attention-backend fa3 \
  --host "${host_ip}" \
  --port 30026 \
  --dist-init-addr "${host_ip}:29526"
```

### NMZ

```Plain Text
同测试模式
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Qwen3\-8B\.w8a8

### 测试模式

```Bash
#!/bin/bash
set -euo pipefail

export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
export SGLANG_ENABLE_SPEC_V2=1
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export HIP_H2D_DISABLE_COPY_BUFFER=0
export HIP_D2H_DISABLE_COPY_BUFFER=0
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768
export HIP_D2H_DIRECT_COPY_THRESHOLD=512
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_MARLIN_W16A16_MOE=1
export HIP_VISIBLE_DEVICES=7
export CUDA_VISIBLE_DEVICES=7

sysctl -w kernel.numa_balancing=0 || true

model_path=/model/vllm-w8a8-models/Qwen3-8B.w8a8
host_ip=<HOST_IP>

cd /tmp/sglang_runtime
mkdir -p server

sglang serve --model-path "${model_path}" --trust-remote-code \
  --numa-node 0 0 1 1 2 2 3 3 \
  --dtype bfloat16 \
  --tensor-parallel-size 1 \
  --page-size 64 \
  --mem-fraction-static 0.9 \
  --attention-backend fa3 \
  --host "${host_ip}" \
  --port 30027 \
  --dist-init-addr "${host_ip}:29527"

```

### NMZ

```Plain Text
同测试模式
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Kimi\-K2\.5/2\.6

### 测试模式

```Bash
export SGLANG_USE_LIGHTOP=1
export SGLANG_USE_OPT_CAT=1
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000
export HIP_GRAPH_ACCUMULATE_DISPATCH=0
export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1
export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

python3 -m sglang.launch_server \
  --model-path /model/Kimi-K2.5 \
  --host $(hostname -I | awk '{print $1}') \
  --port 30000 \
  --trust-remote-code \
  --page-size 64 \
  --dist-init-addr $(hostname -I | awk '{print $1}'):5001 \
  --nnodes 1 \
  --node-rank 0 \
  --dtype bfloat16 \
  --tp-size 8 \
  --pp-size 1 \
  --mem-fraction-static 0.9 \
  --attention-backend dcu_mla \
  --enable-torch-compile \
  --numa-node 0 0 0 0 1 1 1 1 \
  --chunked-prefill-size -1 \
  --max-running-requests 512 \
  --context-length 65536
```

### NMZ

```Plain Text

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
export GLOO_SOCKET_IFNAME=ens61f0np0
export NCCL_SOCKET_IFNAME=ens61f0np0

  --kv-cache-dtype fp8_e5m2 \
  --nnodes 2 \
  --tp-size 8 \
  --pp-size 2 \

```

### KME

```Plain Text
待测试
```

## Qwen3\.5\-122B\-A10B\-W8A8

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0


export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')

port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 3 1 1 0 7 5 5 4 "
option+=" --dtype bfloat16"
option+=" --quantization w8a8_int8"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
     --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log
```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Bash
export HIP_VISIBLE_DEVICES=4,5,6,7
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGLANG_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_KV_LAYOUT_DCU_FA=0
model_path=/model/qwen3.5/Qwen3.5-122B-A10B-W8A8

model=${model_path##*/}
tp=4
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="/shangxl/Test/Qwen3.5/Qwen3.5-122B-A10B-W8A8/log/"
#max_model_len=32768
gpu_mem=0.95
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30005
port1=5002
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --dtype bfloat16"
option+=" --quantization w8a8_int8"
option+=" --disable-radix-cache "
sglang serve --model-path $model_path --trust-remote-code  ${option} \
    --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}/$time.log
```

## Qwen3\.5\-122B\-A10B\-Channel\-FP8

### 测试模式



```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 3 1 1 0 7 5 5 4 "
option+=" --dtype bfloat16"

sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3（精度有问题）
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
不支持
```

## DeepSeek\-V3\-W4A8\-V2

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用

model_path=$1
model=${model_path##*/}
tp=$2
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")

mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
master_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=$3
port1=$4
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 3 1 1 0 7 5 5 4 "
option+=" --dtype bfloat16"
option+="  --mamba-scheduler-strategy extra_buffer"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
        --tensor-parallel-size $tp  --page-size 64 \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $host_ip:$port1 \
                2>&1 | tee ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Qwen3\-VL\-32B\-Instruct

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要
model_path=$1
model=${model_path##*/}
tp=4
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"
sglang serve --model-path $model_path --trust-remote-code  ${option} \
      --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```

## Qwen2\.5\-VL\-32B\-Instruct

### 测试模式

```Bash
export USE_DCU_CUSTOM_ALLREDUCE=1
export SGL_CHUNKED_PREFIX_CACHE_THRESHOLD=0
export SGLANG_DISAGGREGATION_BOOTSTRAP_TIMEOUT=1200
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=0x40000

export SGLANG_TORCH_PROFILER_DIR=/tmp/sglang_profile
export SGLANG_SET_CPU_AFFINITY=1
export HIP_KERNEL_BATCH_CEILING=100
export GPU_MAX_HW_QUEUES=3
sysctl -w kernel.numa_balancing=0

#mtp overlap
export SGLANG_ENABLE_SPEC_V2=1
# triton改写算子
export SGLANG_KVALLOC_KERNEL=1
export SGLANG_CREATE_EXTEND_AFTER_DECODE_SPEC_INFO=1
export SGLANG_ASSIGN_EXTEND_CACHE_LOCS=1
export SGLANG_ASSIGN_REQ_TO_TOKEN_POOL=1
export SGLANG_GET_LAST_LOC=1
export SGLANG_CREATE_FLASHMLA_KV_INDICES_TRITON=1
export SGLANG_CREATE_CHUNKED_PREFIX_CACHE_KV_INDICES=1

#export HIP_GRAPH_ACCUMULATE_DISPATCH=0 #torchprof需要
export HIP_H2D_DISABLE_COPY_BUFFER=0 # 同步异步强制走WriteBuffer
export HIP_D2H_DISABLE_COPY_BUFFER=0 # 同步异步强制走ReadBuffer
export HIP_H2D_DIRECT_COPY_THRESHOLD=32768 # 小于此值走CPUCopy
export HIP_H2D_HSAAPI_COPY_THRESHOLD=32768 # 大于此值走HSACOPY（CopyBuffer）
export HIP_D2H_DIRECT_COPY_THRESHOLD=512 # 小于此值走CPUCopy
export HIP_D2H_HSAAPI_COPY_THRESHOLD=512 # 大于此值走HSACOPY（CopyBuffer）
export SGLANG_USE_FUSED_RMSNORM_ROPE=1
#hiplaunch
export HSA_KERNARG_POOL_SIZE=8388608
export ROC_AQL_QUEUE_SIZE=131072

export NCCL_MAX_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export NCCL_MIN_NCHANNELS=16
export ALLREDUCE_STREAM_WITH_COMPUTE=1

# 融合算子
export SGLANG_USE_LIGHTOP=1  # 使用lightop的rope和topk算子，可用
export SGLANG_USE_MARLIN_W16A16_MOE=1 #int8/int4不需要

model_path=$1
model=${model_path##*/}
tp=4
pp=1
dp=1
ep=1
time=$(date "+%m%d-%H%M")
mode="cudagraph"
logpath="server/$model-tp$tp-dp$dp-ep$ep-$(hostname)"
#max_model_len=32768
gpu_mem=0.9
hostname=$(hostname)
host_ip=$(hostname -I | awk '{print $1}')
#host_ip=0.0.0.0
port=30000
master_ip=$(hostname -I | awk '{print $1}')
rank=0
nodes=1

if [ ! -f ${logpath} ]; then
    mkdir ${logpath} -p
fi

option="--numa-node 0 0 0 0 1 1 1 1 "
option+=" --mm-attention-backend fa3"
option+=" --dtype bfloat16"
      --tensor-parallel-size $tp  --page-size 64 --nnodes $nodes --node-rank $rank \
    --mem-fraction-static $gpu_mem --attention-backend fa3 --host $host_ip  --port $port --dist-init-addr $master_ip:5000 \
                2>&1 | tee  ${logpath}-model_len$max_model_len-mem$gpu_mem-$time-$hostname.log

```

### NMZ

```Plain Text
--kv-cache-dtype fp8_e4m3
```

### BW1000

```Plain Text
--kv-cache-dtype fp8_e5m2
```

### KME

```Plain Text
同测试模式
```



