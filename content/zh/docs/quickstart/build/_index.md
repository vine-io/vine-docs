---
title: "构建工具"
date: 2021-08-27T09:06:02+08:00
draft: false
weight: 4
description: >
---

我们提供一套工具帮助开发者快速构建微服务。
## 安装
使用 go install 安装
```bash
go install github.com/vine-io/vine/cmd/vine@latest
```
编译包安装 (推荐)
```bash
bash -c "$(curl -fsSL https://raw.github.com/vine-io/vine/master/tools/install.sh)"
```
> windows 平台直接去 [release](https://github.com/vine-io/vine/releases/latest) 下载

工具使用
```bash
vine --version
> vine version v1.5.0-5a39306c-1676942884
```

## 新建项目
创建目录作为项目根目录
```bash
mkdir -p $GOPATH/src/foo
```
初始化目录
```bash
cd $GOPATH/src/foo
vine init
```
`vine init [--cluster]` 会初始化 **Vine** 项目，生成以下文件
```bash
.
├── vine.toml  # vine 项目的描述文件，包括项目名称，服务接口和proto等信息。
├── README.md
├── .gitignore
└── go.mod
``` 
## 新建服务
在初始化的目录新建微服务：
```bash
vine new service foo
```
> vine 项目类型为 single 时，`vine new service` 指定服务名称是无效的，它的名称等于目录名。

执行结果，生成以下文档:
```bash
.
├── cmd
│   └── echo
│       └── main.go
├── pkg
│   ├── internal
│   │   ├── storage
│   │   │   └── storage.go
│   │   └── version
│   │       └── version.go
│   └── echo
│       ├── app.go
│       ├── builtin.go
│       ├── server
│       │   └── echo.go
│       └── service
│           └── echo.go
├── deploy
│   ├── docker
│   │   └── echo
│   │       └── Dockerfile
│   ├── config
│   │   └── echo.ini
│   └── systemd
│       └── echo.service
├── api
│   └── services
│       └── echo
│           └── v1
│               └── echo.proto
├── Makefile
└── vine.toml


download protoc zip packages (protoc-$VERSION-$PLATFORM.zip) and install:

visit https://github.com/protocolbuffers/protobuf/releases

download protobuf for vine:

cd github.com/lack-io/foo

install dependencies:
        go get github.com/gogo/protobuf
        go get github.com/vine-io/vine/cmd/protoc-gen-gogo
        go get github.com/vine-io/vine/cmd/protoc-gen-vine
        go get github.com/vine-io/vine/cmd/protoc-gen-validator
        go get github.com/vine-io/vine/cmd/protoc-gen-deepcopy
        go get github.com/vine-io/vine/cmd/protoc-gen-dao

cd github.com/lack-io/foo
        vine build echo
```

## 安装依赖
```bash
go get github.com/gogo/protobuf
go get github.com/vine-io/vine/cmd/protoc-gen-gogo
go get github.com/vine-io/vine/cmd/protoc-gen-vine
go get github.com/vine-io/vine/cmd/protoc-gen-validator
go get github.com/vine-io/vine/cmd/protoc-gen-deepcopy
go get github.com/vine-io/vine/cmd/protoc-gen-dao
```

## 更加 proto 文件生成 go 代码
使用命令格式为: `vine build proto [command options] [proto_name]` 
```bash
# 生成 vine.toml 中所有 proto 文件对应的代码。
vine new proto
```
支持如下参数:
- --type string                      指定 proto 文件的类型，支持 api 和 service，默认 api
- --proto-version string, -v string  指定 proto 文件版本，默认 v1
- --group string                     指定 proto 文件分组，默认 core
- --dir string                       执行 protoc 命令是所在的目录，chroot
- --path strings, -I strings         protoc -I 路径
- --plugins strings, -P strings      生成 proto 时装载的插件

## 运行服务
命令格式: `vine new [command options] [name]`
```bash
vine run foo
```
支持如下参数:
```bash
- --auto-restart                    监听文件变化时重启服务
- --watch strings                   追加监听的路径
- --watch-interval int64, -I int64  监听事件触发间隔，默认3s
```

## 启动 api 网关
命令格式: `vine api [command options]`
```bash
vine api --handler=rpc --enable-openapi
```