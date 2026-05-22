---
NOTE: 精度测试/性能测试前，需要在容器内安装opencompass或evalscop测试工具。
---
# evalscope安装指南

### 1. 拉取代码按照源码安装

```shell
git clone https://github.com/modelscope/evalscope.git
cd evalscope/
pip install -e .
```
执行完毕后通过
`pip list | grep evalscope`来查看安装情况，并返回给用户

### 2. 安装所有依赖

询问用户是否安装所有依赖
得到肯定回复后执行，否则跳过这一步
`pip install '.[all]'`