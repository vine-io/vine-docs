---
title: "protoc-gen-deepcopy"
date: 2021-08-27T09:38:29+08:00
draft: false
weight: 6
description: >
  使用 protoc-gen-deepcopy 生成资源的 deepcopy 接口。
---

## 概述
protoc-gen-deepcopy 帮助用户生成资源的深拷贝接口，减少用户编写代码。 

## 使用
### 1.先编写 deepcopy.proto 文件
```protobuf
// +gen:deepcopy
message Person {
  string name = 1;
  bytes any = 3;
  string email = 4;
}
```
### 2.安装 protoc-gen-deepcopy
```bash
go get github.com/vine-io/vine/cmd/protoc-gen-deepcopy
```

### 3.生成 Validate() 方法
```bash
protoc -I=$GOPATH/src --gogo_out=:.  --deepcopy_out=:. proto/deepcopy.proto
```
执行完成后生成以下代码:
```golang
// DeepCopyInto is an auto-generated deepcopy function, coping the receiver, writing into out. in must be no-nil.
func (in *Person) DeepCopyInto(out *Person) {
	*out = *in
}

// DeepCopy is an auto-generated deepcopy function, copying the receiver, creating a new Person.
func (in *Person) DeepCopy() *Person {
	if in == nil {
		return nil
	}
	out := new(Person)
	in.DeepCopyInto(out)
	return out
}
```
### 4.验证
```golang
func main() {
	p := &helloworld.Person{
		Name:  "Vine",
		Any:   []byte("Hello"),
		Email: "aa@gmail.com",
	}

	fmt.Printf("%p %v\n", p, p)
	pc := p.DeepCopy()
	fmt.Printf("%p %v\n", pc, pc)
}
// output:  
//  0xc0002ea280 name:"Vine" any:"Hello" email:"aa@gmail.com"
//  0xc0002ea2c0 name:"Vine" any:"Hello" email:"aa@gmail.com"
```

## 语法解析
`protoc-gen-deepcopy` 通过解析 `protobuf` 中的注释来生成 `deepcopy` 接口。
```protobuf
// +gen:deepcopy
message Struct {
    string field1 = 1;
    string field2 = 2;
}
```

### 语法规则
有效的注释有以下的规则:
- 注释必须以 `+gen` 作为开头
- 注释的内容必须紧贴对应的字段，中间不能有空行

### 类型支持
`message` 类型规则:
- deepcopy: 生成 DeepCopy 方法
```protobuf
// +gen:deepcopy
message P {
}
```
