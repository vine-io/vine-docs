---
title: "Dao"
date: 2021-01-18T11:11:29+08:00
draft: false
weight: 3
description: >
  *Dao* 通过 `protoc-gen-dao` 生成数据库CURD代码。
---

## 概述
**Vine** 提供 `protoc-gen-dao` 工具通过识别`*.proto`文件的注释

## 使用
### 1.先编写 validator.proto 文件
```protobuf
message Person {
  // +gen:min_len=4
  // +gen:max_len=10
  string name = 1;

  // +gen:required;gt=10;lt=100
  int32 age = 2;

  // +gen:required;min_bytes=3;max_bytes=4;
  bytes any = 3;

  // +gen:email
  string email = 4;
}
```
### 2.安装 protoc-gen-validator
```bash
go get github.com/lack-io/vine/cmd/protoc-gen-validator
```

### 3.生成 Validate() 方法
```bash
protoc -I=$GOPATH/src --gogofaster_out=plugins=grpc:.  --validator_out=:. proto/validator.proto
```
执行完成后生成以下代码:
```golang
func (m *Person) Validate() error {
	errs := make([]error, 0)
	if len(m.Name) != 0 {
		if !(len(m.Name) >= 4) {
			errs = append(errs, errors.New("field 'name' length must less than '4'"))
		}
		if !(len(m.Name) <= 10) {
			errs = append(errs, errors.New("field 'name' length must great than '10'"))
		}
	}
	if int64(m.Age) == 0 {
		errs = append(errs, errors.New("field 'age' is required"))
	} else {
		if !(m.Age < 100) {
			errs = append(errs, errors.New("field 'age' must less than '100'"))
		}
		if !(m.Age > 10) {
			errs = append(errs, errors.New("field 'age' must great than '10'"))
		}
	}
	if len(m.Any) == 0 {
		errs = append(errs, errors.New("field 'any' is required"))
	} else {
		if !(len(m.Any) <= 3) {
			errs = append(errs, errors.New("field 'any' length must less than '3'"))
		}
		if !(len(m.Any) >= 4) {
			errs = append(errs, errors.New("field 'any' length must great than '4'"))
		}
	}
	if len(m.Email) != 0 {
		if !is.Email(m.Email) {
			errs = append(errs, errors.New("field 'email' is not a valid email"))
		}
	}
	return is.MargeErr(errs...)
}
```
### 4.验证
```golang
func main() {
 	p := pb.Person{}
	p.Age = 1
	p.Email = "11"
 	err := p.Validate()
 	log.Printf("%v\n", err)
}
// output:  field 'age' must great than '10';field 'any' is required;field 'email' is not a valid email
```
多个错误时，使用 `;` 隔开

## 语法解析
`protoc-gen-validator` 通过解析 `protobuf` 中的注释来生成 `Validate()` 规则。
```protobuf
// +gen:ignore
message Struct {
    // +gen:required
    string field1 = 1;
    
    // +gen:required;email
    // +gen:min_len=3
    string field2 = 2;
}
```

### 语法规则
有效的注释有以下的规则:
- 注释必须以 `+gen` 作为开头
- 注释的内容必须紧贴对应的字段，中间不能有空行
- 支持多行注释，也可以将多行合并成一行，并用 `;` 作为分隔符

### 类型支持
`message` 类型规则:
- ignore: 忽略该 message ，不生成 `Validate()` 方法

```protobuf
// +gen:ignore
message P {

}
```

`message` 作为内嵌字段时支持的规则:
- required: 判断该字段是否为 nil。

```protobuf
message P {
    // +gen:required
    Sub sub = 1;
}

message Sub {

}
```

> 注: 在引用外部的 message 时，请确认 message 存在 Validate() 方法

`string` 类型支持的规则
- required: 判断是否为空
- default: 字段为空时指定的默认值，(不可用 required 同时使用)
- in, enum: 判断字段的值是否存在于指定的列表中
- not_in: 判断字段的值是否在指定的列表之外
- min_len: 指定字段的最小长度
- max_len: 指定字段的最大长度
- prefix: 判断字段是否以给定的值为开头
- suffix: 判断字段是否以给定的值为结尾
- contains: 判断字段是否包含给定的值
- pattern: 判断该字段是否为有效的正则表达式
- number: 判断该字段是否为有效数字
- email: 判断该字段是否为有效的邮箱地址
- ip: 判断该字段是否为有效的 ip 地址
- ipv4: 判断该字段是否为有效的 ipv4
- ipv6: 判断该字段是否为有效的 ipv6
- crontab: 判断该字段是否为有效的 crontab 表达式
- uuid: 判断该字段是否为有效的 uuid v4
- uri: 判断该字段是否为有效的 uri
- domain: 判断该字段是否为有效的域名

```protobuf
message S {
    // +gen:required
    // +gen:default="hello"
    // +gen:in=["1", "2", "3"]
    // +gen:enum=["a", "b", "c"]
    // +gen:not_in=["d", "s"]
    // +gen:min_len=3
    // +gen:min_max=4
    // +gen:prefix="http"
    // +gen:suffix=".com"
    // +gen:contains="www"
    // +gen:pattern=`\d+(\w+){3,5}`
    // +gen:number
    // +gen:ip
    // +gen:ipv4
    // +gen:ipv6
    // +gen:crontab
    // +gen:uuid
    // +gen:uri
    // +gen:domain
    string m = 1;
}
```

> 注: string pattern 最好单独一行，以免和其他规则冲突

数字类型的支持，包含 int32, int64, fixed32, fix64, float, double
- required: 判断是否为 0
- default: 字段为空时指定的默认值，(不可用 required 同时使用)
- in, enum: 判断字段的值是否存在于指定的列表中
- not_in: 判断字段的值是否在指定的列表之外
- lt: 指定字段小于指定值
- lte: 指定字段的小于等于指定值
- gt: 指定字段大于指定值
- gte: 指定字段大于等于指定值

```protobuf
message S {
    // +gen:required
    float a = 1;

    // +gen:default=3.14
    double pi = 2

    // +gen:in=[1,2,3]
    // +gen:enum=[2,3]
    // +gen:not_in=[4,5]
    int32 b = 3;

    // +gen:ge=3
    // +ggen:gte=4
    // +gen:lte=9
    // +gen:lt=10
    int64 c = 4;
}
```

`bytes` 类型的支持:
- required: 判断字段的长度是否为0
- min_bytes: 判断字段的最小字节数是否大于给定值
- max_bytes: 判断字段的最大字节数是否小于给定值

```protobuf
message S {
    // +gen:required
    // +gen:min_bytes=10
    // +gen:min_bytes=1024
    bytes any = 1;
}
```

repeated 类型的支持：repeated 类型的字段在 golang 中会被解析成切片。
- required: 判断切片的长度是否为0
- min_len: 判断切片的最小长度是否大于给定值
- max_len: 判断切片的最大长度是否小于给定值

```protobuf
message S {
    // +gen:required
    // +gen:min_len=3
    // +gen:max_len=5
    repeated string = 1;
}
```

