---
title: "服务部署"
date: 2021-08-27T09:40:02+08:00
draft: false
weight: 5
description: >
---

这个我们介绍两种服务部署方式。

## docker
**Vine** 中默认提供了用于构建程序的 Dockerfile 文件。用于构建服务镜像。

### Dockerfile
编辑 `_output/Dockerfile` 
```dockerfile
FROM debian:stable-slim
ADD helloworld /helloworld

EXPOSE 11500

ENTRYPOINT [ "/helloworld", "--server.address=0.0.0.0:11500" ]
```
### 编译项目
```bash
vine build service --output=_output/helloworld 
```
### 构建镜像
```bash
cd _output
docker build -t helloworld .
```

### 启动服务
```go
docker run --rm -p 11500:11500 helloworl
```

## gpm
[gpm](https://github.com/vine-io/gpm) 是基于 **Vine** 开发的项目管理服务。合适于在没有 docker 环境的机器上管理 **Vine** 服务。

### 启动 gpm 
```go
gpm start -A '--server.address=0.0.0.0:7700'
```

### 服务打包
```bash
gpm tar --name helloworld.tar.gz --target main
```

### 安装服务
```bash
gpm --host 192.168.3.111:7700 install --package helloworld.tar.gz --name helloworld --dir /opt/helloworld --bin /opt/helloworld/main --args '--server-address=0.0.0.0:11500' --version v1.0.0
```

### 启动服务
```bash
gpm --host 192.168.3.111:7700 start --name helloworld
```