---
title: "服务网关"
date: 2020-12-29T14:58:34+08:00
draft: false
weight: 8
description: >
---

## 概述
**API** 是一个可插拔的 API 接口，由 **Registry** 驱动，可帮助构建强大的公共 API 网关.

**API** 库提供 api 网关路由功能。微服务体系结构将应用程序逻辑分离到单独的服务中. api 网关提供单个入口点，以将这些服务合并到统一 api 中。 **API** 使用在 **Registry** 元数据中定义的路由来生成路由规则并服务 http 请求.

## 启动 api 服务
```bash
# 提供 http 服务和 swagger 
vine api --handler=rpc --enable-openapi
```
## 创建网关
```bash
vine new gateway api
```
启动
```bash
go run cmd/api/main.go --api-address=127.0.0.1:8080
```
> 一个服务同时提供 gRPC 和 http 接口可以参考 [api](https://github.com/vine-io/examples/tree/main/api)
## 测试
```bash
curl -X POST "http://127.0.0.1:8080/helloworld/v1/helloworld/Call" -H  "accept: application/json" -H  "Content-Type: application/json" -d "{\"name\":\"hello\"}"
> {"msg":"reply: hello"}
```
