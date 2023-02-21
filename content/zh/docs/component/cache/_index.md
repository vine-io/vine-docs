---
title: "数据缓存"
date: 2020-12-29T15:01:40+08:00
draft: false
weight: 90
description: >
---
## 概述
**Vine** 提供 `Cache` 作为分布式缓存接口。 
```go
// Cache is a data cache interface
type Cache interface {
	// Init initialises the cache. It must perform any required setup on the backing storage implementation and check that it is ready for use, returning any errors.
	Init(...Option) error
	// Options allows you to view the current options.
	Options() Options
	// Get takes a single key name and optional GetOptions. It returns matching []*Record or an error.
	Get(ctx context.Context, key string, opts ...GetOption) ([]*Record, error)
	// Put writes a record to the cache, and returns an error if the record was not written.
	Put(ctx context.Context, r *Record, opts ...PutOption) error
	// Del removes the record with the corresponding key from the cache.
	Del(ctx context.Context, key string, opts ...DelOption) error
	// List returns any keys that match, or an empty list with no error if none matched.
	List(ctx context.Context, opts ...ListOption) ([]string, error)
	// Close the cache
	Close() error
	// String returns the name of the implementation.
	String() string
}

// Record is an item cached or retrieved from a Cache
type Record struct {
	// The key to cache the record
	Key string `json:"key"`
	// The value within the record
	Value []byte `json:"value"`
	// Any associated metadata for indexing
	Metadata map[string]interface{} `json:"metadata"`
	// Time to expire a record: TODO: change to timestamp
	Expiry time.Duration `json:"expiry,omitempty"`
}
```
## 使用 

### 初始化
```go
package main

import (
	"fmt"
	"log"
	"time"

	"github.com/vine-io/vine/lib/cache"
	"github.com/vine-io/vine/lib/cache/memory"
)

func main() {
	cc := memory.NewCache()
	if err := cc.Init(); err != nil {
		log.Fatalln(err)
	}
	defer cc.Close()
}
```
### 插入 key/value
```go
func main() {
	// cache.Record
	r := &cache.Record{
		Key:      "a", // key 唯一值
		Value:    []byte("hello"), // value
		Metadata: map[string]interface{}{}, // 
		Expiry:   time.Second * 3, // 过期时间
	}
	if err := cc.Put(context.TODO(), r); err != nil {
		log.Fatalln(err)
	}
}
```
### 获取 key/value
```go
func main() {
	// 获取所有 keys
	keys, err := cc.List(context.TODO())
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(keys)

	// 通过 key 获取 value
	rr, err := cc.Get(context.TODO(), "a")
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(string(rr[0].Value))
}
```
### 删除 key
```go
func main() {
	if err := cc.Del(context.TODO(), "a"); err != nil {
		log.Fatalln(err)
	}
}
```
## options
初始化 options
```go
func main() {
	cc := memory.NewCache(
		cache.Nodes(),    // 指定缓存服务器的节点信息
		cache.Table(),    // 指定 table
		cache.Database(), // 指定 database
		cache.WithClient(), // 指定 Client 接口实现
		cache.WithContext(), // 指定 context.Context
	)
}
```
`Put` options
```go
func main() {
	cc.Put(context.TODO(), r,
		cache.PutExpiry(), // 指定 key 过期时间
		cache.PutTo(),     // 指定 database 和 table
		cache.PutTTL(),    // 指定 key ttl
	)
}
```
`List` options
```go
func main() {
	keys, err := cc.List(
		context.TODO(),
		cache.ListFrom(),  // 指定 database 和 table
		cache.ListLimit(), // 限制 key 数量
		cache.ListOffset(), // 查询偏移量
		cache.ListPrefix(), // 指定 key 前缀
		cache.ListSuffix(), // 指定 key 后缀
	)
}
```
`Get` options
```go
func main() {
	cc.Get(context.TODO(), "a",
		cache.GetFrom(), // 指定 database 和 table
		cache.GetLimit(), // 限制 key 数量
		cache.GetOffset(), // 查询偏移量
		cache.GetPrefix(), // 指定 key 前缀
		cache.GetSuffix(), // 指定 key 后缀
	)
}
```
`Del` options
```go
func main() {
	cc.Del(context.TODO(), "a",
		cache.DelFrom(), // 指定 database 和 table
	)
}
```