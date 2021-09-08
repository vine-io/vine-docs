---
title: "元数据"
date: 2021-08-27T09:32:02+08:00
draft: false
weight: 4
description: >
---

## 简介
> 元数据是用来描述数据的数据（Data that describes other data）。

**Vine** 中的元数据统一封装在 `context.Context` 中。通过 wrapper 的特性使我们可以在无入侵的情况下修改元数据信息。

## metadata
`metadata` 模块用于 **Vine** 元数据的操作，支持的操作如下：
```go
import (
    "context"
    "github.com/vine-io/vine/util/context/metadata"
)

func main() {
    // 从 ctx 获取 key
    val, ok := metadata.Get(ctx, "key")
    // 修改 ctx 中的 key
    metadata.Set(ctx, "key", "value")
    // 删除 ctx 中的 key
    metadata.Delete(ctx, "key")
    // 获取 ctx 中的元数据
    md, _ := metadata.FromContext(ctx)
    // 封装 md
    ctx = metadata.NewContext(ctx, md)
    // 完整拷贝元数据
    md = metadata.Copy(md)
    // 合并 ctx 中的元数据
    ctx = metadata.MergeContext(ctx, md, true)
}
```
## 使用 
在有 ctx 作为入参的地方都可以使用 metadata。如果不希望破坏业务代码，推荐在 wrapper 中使用:
```go
func CallWrapper() client.CallWrapper {
	return func(fn client.CallFunc) client.CallFunc {
		return func(ctx context.Context, node *registry.Node, req client.Request, rsp interface{}, opts client.CallOptions) error {
			md, _ := metadata.FromContext(ctx)
			// 追加 client=wrapper
			md.Set("client", "wrapper")
			ctx = metadata.NewContext(ctx, md)
			return fn(ctx, node, req, rsp, opts)
		}
	}
}

func HandlerWrapper() server.HandlerWrapper {
	return func(fn server.HandlerFunc) server.HandlerFunc {
		return func(ctx context.Context, req server.Request, rsp interface{}) error {
			val, _ := metadata.Get(ctx, "client")
            // 获取 client
			fmt.Println("client: ", val)
			return fn(ctx, req, rsp)
		}
	}
}
```

