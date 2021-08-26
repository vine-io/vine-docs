---
title: "配置"
date: 2020-12-29T14:56:14+08:00
draft: false
weight: 5
description: >
  **Config** 是一个可插拔的动态配置库
---

## 概述
应用程序中的大多数配置都是静态配置或者从多个源加载的复杂逻辑。**Config** 是其变得简单，可插拔和可合并。

## 特性

- **动态加载** - 在需要时从多个源加载配置. **Config** 管理在后台监听配置源，并自动合并和更新内存中的配置文件源。
- **可插拔的源** - 从任意数量的源中进行选择以加载和合并配置。后端源被抽象为内部使用并通过编码器解码的标准格式。源可以是 env vars, flags, etcd, k8s configmap, 等。
- **可合并配置** - 如果指定多个配置源，无论格式如何，它们都将合并并在单个视图中显示。这极大地简化了基于环境的优先级顺序加载和更改。
- **改动监听** - 可选择监听配置，以监控特定值的更改。使用 **Config** 的监听程序热加载你的应用。不必临时关机重新加载其他任何内容，只需继续读取配置并监听需要通知的更改。
- **安全恢复** - 如果配置负载严重或由于未知原因完全擦除，则可以在直接访问任何配置值时指定回退值。这可确保在发生问题时始终读取某些合理的默认值。

## 内部实现
下面介绍 **Config** 的实现，**Config** 有以下部分组成：
- source: 配置的来源
- encoder: 处理编码/解码源配置
- reader: 将多个编码源合并为单一格式
- loader：管理加载源

### Source
`Source` 作为配置的读取来源。可以同时使用多个源。
支持以下源:
- cli : 从 CLI 标志读取
- env : 从环境变量中读取
- file : 从文件中读取
- flag : 从标志中读取
- memory : 从内存中读取

### ChangeSet
**Source** 将 **Config** 作为一个 **ChangeSet** 返回，作为多个源的单一内部抽象。
```go
// ChangeSet represents a set of changes from a source
type ChangeSet struct {
	Data      []byte
	CheckSum  string
	Format    string
	Source    string
	Timestamp time.Time
}
```

### encoder
`Encoder` 处理编码和解码。后端源可能以许多不停的格式存储。编码器使我们能够处理任何格式。如果未指定编码器，则默认为 json。
支持以下编码格式：
- json
- yaml
- toml
- xml
- hcl

### reader
`Reader` 将多个 **ChangeSet** 表示为单个合并和查询的集合
```go
// Reader is an interface for merging changesets
type Reader interface {
    // Merge multiple changeset into a single format
    Merge(...*source.ChangeSet) (*source.ChangeSet, error)
    // Return Go assertable values
    Values(*source.ChangeSet) (Values, error)
    // Name of the reader e.g json reader
	String() string
}
```
`Reader` 使用 `Encoder` 将 **ChangeSet** 解码为 `map[string]Values`，然后将它们合并到单个 **ChangeSet** 中。
```go
// Values is returned by the reader
type Values interface {
	Bytes() []byte
	Get(path ...string) Value
	Set(val interface{}, path ...string)
	Del(path ...string)
	Map() map[string]interface{}
	Scan(v interface{}) error
}
```
`Value` 接口允许强制转换，类型断言，返回默认值
```go
// Value represents a value of any type
type Value interface {
	Bool(def bool) bool
	Int(def int64) int64
	String(def string) string
	Float64(def float64) float64
	Duration(def time.Duration) time.Duration
	StringSlice(def []string) []string
	StringMap(def map[string]string) map[string]string
	Scan(val interface{}) error
	Bytes() []byte
}
```

### Config
**Config** 管理所有配置，抽象 source，encoder，reader。
它从多个源读取，同步，监听，并将它们合并为单个可查询的源。
```go
// Config is an interface abstraction for dynamic configuration
type Config interface {
	// provide the reader.Values interface
	reader.Values
	// Init the config
	Init(opts ...Option) error
	// Options in the config
	Options() Options
	// Stop the config loader/watcher
	Close() error
	// Load config sources
	Load(source ...source.Source) error
	// Force a source changeset sync
	Sync() error
	// Watch a value for changes
	Watch(path ...string) (Watcher, error)
}
```

## 使用
### 实例配置
只要我们有一个编码器来支持它，配置文件就可以是任务格式的。
json 配置实例：
```json
{
    "hosts": {
        "database": {
            "address": "10.0.0.1",
            "port": 3306
        },
        "cache": {
            "address": "10.0.0.2",
            "port": 6379
        }
    }
}
```

### 创建 Config
创建一个新 **Config**
```go
import "github.com/vine-io/vine/services/config"

conf := config.NewConfig()
```

### 加载文件
从文件加载配置，根据文件扩展名来确定配置格式。
```go
import "github.com/vine-io/vine/services/config"

// 加载 json 配置文件
config.LoadFile("/tmp/config.json")
```

如果扩展不存在，可指定 `encoder`。
```go
package main

import (
	"github.com/vine-io/vine/service/config"
	"github.com/vine-io/vine/service/config/encoder/toml"
	"github.com/vine-io/vine/service/config/source"
	"github.com/vine-io/vine/service/config/source/file"
)

func main() {
	enc := toml.NewEncoder()
	
	// 通过编码器加载 toml 文件
	config.Load(
		file.NewSource(
			file.WithPath("/tmp/config"),
			source.WithEncoder(enc),
		),
	)
}
```
### 读取配置
```go
conf := config.Map()

fmt.Println(conf["hosts"])
```
扫描配置到结构体
```go
type Host struct {
	Address string `json:"address"`
	Port int `json:"port"`
}

type Config struct {
	Hosts map[string]Host `json:"hosts"`
}

func main() {
	pwd, _ := os.Getwd()
	err := config.LoadFile(pwd + "/config/" + "config.json")
	if err != nil {
		log.Fatal(err)
	}

	var cfg Config
	config.Scan(&cfg)

	fmt.Println(cfg.Hosts["database"].Address)
}
```
### 读取值
从配置扫描值到结构体
```go
type Host struct {
    Address string  `json:"address"`
    Port    int     `json:"port"`
}

var host Host

config.Get("hosts", "database").Scan(&host)

// 10.0.0.1 3306
fmt.Println(host.Address, host.Port)
```

读取单个值作为 Go 类型
```go
// Get address. Set default to localhost as fallback
address := config.Get("hosts", "database", "address").String("localhost")

// Get port. Set default to 3000 as fallback
port := config.Get("hosts", "database", "port").Int(3000)
```

### 监听配置
监听配置文件。当文件更改时，更新到新值:
```go
w, err := config.Watch("hosts", "database")
if err != nil {
    // do something
}

// wait for next value
v, err := w.Next()
if err != nil {
    // do something
}

var host Host

v.Scan(&host)
```

### 多源
可以加载和合并多个源。合并优先级顺序相反:
```go
config.Load(
    // base config from env
    env.NewSource()
    // override env with flags
    flag.NewSource()
    // override flags with file
    file.NewSource(file.WatchPath("/tmp/config.json"))
)
```

### 设置源编码器
源要求编码器对数据进行编码 / 解码并指定更改集格式.

默认的编码器是 json. 要更改编码器可调整对应的类型选项.
```go
e := yaml.NewEncoder()

s := consul.NewSource(
    source.WithEncoder(e),
)
```
### 添加读取器编码器
读取器使用编码器从不同格式的源解码数据.

默认的读取器支持 json, yaml, xml, toml 和 hcl. 它将合并的配置表示为 json.

可以通过指定的选项来添加一个新的编码器.
```go
e := yaml.NewEncoder()

r := json.NewReader(
    reader.WithEncoder(e),
)
```