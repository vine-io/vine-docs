---
title: "新建项目"
date: 2021-08-26T16:08:25+08:00
draft: false
weight: 2
description: >
---

## 依赖
新建 **Vine** 项目需要安装依赖环境和工具:
- [go](https://golang.org/dl/)
- [protoc](https://github.com/protocolbuffers/protobuf)

建议开启GO111MODULE
```bash
go env -w GO111MODULE=on
```

## 安装
安装 **Vine** 工具

go get 安装
```bash
go get -u github.com/vine-io/vine/cmd/vine@latest
go get -u github.com/vine-io/vine/cmd/protoc-gen-gogo@latest
go get -u github.com/vine-io/vine/cmd/protoc-gen-vine@latest
```
go install 安装
```bash
go install github.com/vine-io/vine/cmd/vine@latest
go install github.com/vine-io/vine/cmd/protoc-gen-gogo@latest
go install github.com/vine-io/vine/cmd/protoc-gen-vine@latest
```
源码编译安装
```bash
git clone https://github.com/vine-io/vine
cd vine
make build && mv vine $GOPATH/bin/vine 
```

## 创建项目
```bash
# 新建项目根目录
mkdir -p $GOPATH/src/helloworld
cd $GOPATH/src/helloworld

# 初始化目录
vine init
# 新建服务
vine new service helloworld
# 生成代码
vine build proto
# 安装依赖
go mod vendor
# 启动服务
vine run helloworld
```

## 启动服务
```bash
vine run helloworld
```

## 启动网关
```bash
vine api --handler=rpc --enable-openapi
```

## 测试
```bash
curl -X POST http://127.0.0.1:8080/foo/v1/foo/Call -H "Content-Type: application/json"  -d "{\"name\":\"World\"}"
# {"msg":"reply: World"}
```