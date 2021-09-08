---
title: "Protobuf 规范"
date: 2021-08-27T09:35:18+08:00
draft: false
weight: 1
description: >
---

我们提供一套 `Protobuf` 文件格式和神生成代码的规范，帮助用户写出更标准的接口。

**Vine** 项目的推崇以 **资源** 为核心。接口的设计和代码的规范都按照 **资源** 展开。每个接口的设计遵循以下的规则:
1. 根据需求确定资源 (领域模型)。
2. 每个接口实际为资源的方法或者是针对资源的操作。
3. 每个 service 为资源操作的集合。
4. 前端请求时提交的数据可直接转化为资源的内部属性。
5. 提供的 API 接口格式统一为针对资源的曹组。

## 目录结构
API 接口统一存放在 api 目录下，proto 文件同时转化为 gRPC 和 HTTP 两种接口。

项目中定义 Proto，以 api 为根目录。
```bash
├── service    
│   └── helloworld
│       └── v1
│           ├── helloworld.pb.go
│           ├── helloworld.pb.validator.go
│           ├── helloworld.pb.vine.go
│           └── helloworld.proto
└── types
    └── core
        └── v1
            ├── core.pb.dao.go
            ├── core.pb.deepcopy.go
            ├── core.pb.go
            ├── core.pb.validator.go
            └── core.proto
```
api 下有两个子目录，分别对应 
- types (领域模型或者资源)，格式为 `group/version/name.proto`
- services (gRPC、http 接口)，格式为 `service/version/name.proto`

## 包名
包名为应用的标识，用户生成 gRPC 请求路径，或者 proto 文件之间引用。

> 建议在 $GOPATH/src 生成代码 proto 代码。

### go_package
```protobuf
option go_package = "github.com/lack-io/foo/api/types/<group>/<version>;<group><version>";
```
### java_package
```protobuf
option java_multiple_files = true;
option java_package = "io.vine.services.<group>.<version>";
```

## import
service proto 依赖 types protobuf，以 $GOPATH/src 为更目录引入对应 proto。
```protobuf
import "github.com/vine-io/foo/api/types/core/v1/core.proto"

message Request {
    corev1.Request req = 1;
}
```

## repo
当需要数据持久化时，有 types proto 生成对应的数据库交互代码。详细的说明可以参考 [proto-gen-dao](https://vine-io.github.io/vine/docs/guides/dao/)。

代码的存放规则为，*谁实现，谁存放*。生成的代码存放在对应服务更目录的 `infra/repo` 下，需要在 proto 文件的头部指定生成路径:
```protobuf
// +dao:output=github.com/vine-io/foo/pkg/helloworld/infra/repo;repo
syntax = "protoc"
```
## 命令规范
### 目录结构
包名为小写，且同与目录一致: 如 `hellowrold/v1/helloworld.proto` 的包名为 `helloworldv1`。
### 文件结构
文件应该命名为：lower_snake_case.proto 所有Proto应按下列方式排列:
- License header (if applicable)
- File overview
- Syntax
- Package
- Imports (sorted)
- File options
- Service
- Message

### Service 和 Message
使用驼峰命名法命名 service, method 和 message。Service 的名称格式为 `<PackageName>Service` 以 `Service` 为后缀。

Method 的格式为:
```protobuf
service EchoService {
    rpc EmptyMethod(Empty) returns (Empty);
    rpc Echo(EchoReq) returns (EchoRsp);
}

message Empty {}

message EchoReq {}

message EchoRsp {}
```
Method 的输入输出 Message 没有其他字段时，使用 `Empty`。Method 的输入 message 以 `Req` 结尾。输出 message 以 `Rsp` 结尾。

### 字段
字段使用驼峰命名法(首字母小写)，`repeated` 数组类型是结尾加小写:
```protobuf
message User {
    string name = 1;
    repeated string tags = 2;
}
```

### 枚举 Enums
使用驼峰命名法（首字母大写）命名枚举类型，使用 “大写下划线大写” 的方式命名枚举值：
```protobuf
enum Color {
  RED = 0;
  BLACK = 1;
}
```
每一个枚举值以分号结尾，而非逗号。

### 注释 Comment
- Service，描述清楚服务的作用
- Method，描述清楚接口的功能特性
- Field，描述清楚字段准确的信息

## 完整实例
```protobuf
syntax = "proto3";

package gpmv1;

option go_package = "github.com/vine-io/gpm/api/service/gpm/v1;gpmv1";
option java_multiple_files = true;
option java_package = "io.vine.services.gpm.v1";

import "github.com/vine-io/gpm/api/types/gpm/v1/gpm.proto";

// +gen:openapi
service GpmService {
  // +gen:summary=查询单个服务
  // +gen:get=/api/v1/Service/{name}
  rpc GetService(GetServiceReq) returns (GetServiceRsp);
}

message Empty {}

// GetService 请求参数
message GetServiceReq {
  // 服务名称
  // +gen:required
  string name = 1;
}

// GetService 返回结果
message GetServiceRsp {
  gpmv1.Service service = 1;
}
```