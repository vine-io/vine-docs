---
title: "数据库接口"
date: 2021-08-27T09:23:41+08:00
draft: false
weight: 300
description: >
---
## 概述
我们整合 [gorm](https://gorm.io/)，并抽象出 `Dao` 作为数据库交互工具：
```go
// Dialect DAO database dialect
type Dialect interface {
	Init(...Option) error
	Options() Options
	NewTx() *DB
	Migrator() Migrator
	DataTypeOf(*schema.Field) string
	DefaultValueOf(*schema.Field) clause.Expression
	BindVarTo(writer clause.Writer, stmt *Statement, v interface{})
	QuoteTo(clause.Writer, string)
	Explain(sql string, vars ...interface{}) string
	JSONBuild(column string) JSONQuery
	JSONDataType() string
	String() string
}
```
## 使用
`Dao` 的接口语法和 [gorm](https://gorm.io/) 兼容
```go
package main

import (
	"fmt"
	"log"
	"time"

	"github.com/vine-io/plugins/dao/mysql"
	"github.com/vine-io/vine/lib/dao"
	"github.com/vine-io/vine/lib/dao/logger"
)

type User struct {
	Id   int32  `dao:"column:id;autoIncrement;primaryKey"`
	Name string `dao:"column:name"`
	Age  int32  `dao:"column:age"`
}

func main() {
	dns := `root:123456@tcp(192.168.3.111:3306)/vine?charset=utf8&parseTime=True&loc=Local`
	dialect := mysql.NewDialect(dao.DSN(dns), dao.Logger(logger.New(logger.Options{
		SlowThreshold: 200 * time.Millisecond,
		LogLevel:      logger.Info,
	})))
    // 初始化
	if err := dialect.Init(); err != nil {
		log.Fatalln(err)
	}

    // 创建一个新的会话
	db := dialect.NewTx()

    // 更新表结构
	if err := db.AutoMigrate(&User{}); err != nil {
		log.Fatalln(err)
	}

	u := &User{Name: "Mimi", Age: 11}
    // 插入一条记录
	if err := db.Create(u).Error; err != nil {
		log.Fatalln(err)
	}

	u1 := &User{}
    // 查询
	if err := db.Find(&u1, "name = ?", "Mimi").Error; err != nil {
		log.Fatalln(err)
	}

	fmt.Println(u1)

	if err := db.Where("name = ?", "Mimi").First(&u1).Error; err != nil {
		log.Fatalln(err)
	}

	fmt.Println(u1)

	u1.Name = "Mimi_update"
    // 更新一条记录
	if err := db.Updates(u1).Error; err != nil {
		log.Fatalln(err)
	}

    // 删除一条记录
	if err := db.Delete(&User{}, "id = ?", 1).Error; err != nil {
		log.Fatalln(err)
	}
}
```
更多 CURD 的使用方式可以参考[这里](https://gorm.io/docs/create.html)。

