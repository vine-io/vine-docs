---
title: "protoc-gen-dao"
date: 2021-01-18T11:11:29+08:00
draft: false
weight: 7
description: >
  *Dao* 通过 `protoc-gen-dao` 生成数据库CURD代码。
---

## 概述
`Dao` 是 **Vine** 框架的数据库交互模块，而`protoc-gen-dao`工具则可以通过识别`*.proto`来生成对应的数据库交互代码。减少大量重复代码的编写，提高用户效率。

## 使用
### 1.先编写 user.proto 文件
```protobuf
syntax = "proto3";

package v1;

// +gen:dao
message User {
  // +gen:primaryKey
  string id = 1;

  string name = 2;

  repeated string following = 3;

  map<string, string> tags = 4;

  Other other = 5;
}

message Other {
  string k = 1;
  string v = 2;
}
```
### 2.安装 protoc-gen-dao
```bash
go get github.com/vine-io/vine/cmd/protoc-gen-dao
```

### 3.生成CURD代码
```bash
protoc -I=$GOPATH/src --gogo_out=:. --dao_out=:. proto/dao.proto
```
执行完成后生成以下文件:
```bash
-rw-r--r--  1 lack  staff   7.8K Mar 19 22:26 user.pb.dao.go
-rw-r--r--  1 lack  staff    20K Mar 19 22:26 user.pb.go
-rw-r--r--  1 lack  staff   255B Mar 18 23:00 user.proto
```
`*.pb.dao.go` 中保存着CURD代码。
### 4.CURD 实例
```golang
func main() {
	db, err := gorm.Open(sqlite.Open("dao.db"), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	s := v1.NewUserStorage(db, &v1.User{})
	// 注册 Schema, 会在数据库中创建对应的表
	if err := s.AutoMigrate(); err != nil {
		log.Fatal(err)
	}

	ctx := context.TODO()

	user := &v1.User{
		Id:        "1",
		Name:      "lack",
		Following: []string{"a", "b"},
		Tags:      map[string]string{},
		Other: &v1.Other{
			K: "k",
			V: "v",
		},
	}

	fmt.Println("Create ==============>")
	s = v1.NewUserStorage(db, user)
	out, err := s.XXCreate(ctx)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(out)

	fmt.Println("Updates ==============>")
	s = v1.NewUserStorage(db, &v1.User{Id: "1", Name: "lack_rename"})
	out, err = s.XXUpdates(ctx)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(out)

	fmt.Println("FindAll ==============>")
	s = v1.NewUserStorage(db, &v1.User{Following: []string{"a"}})
	outs, err := s.XXFindAll(ctx)
	fmt.Println(outs)

	fmt.Println("FindOne ==============>")
	s = v1.NewUserStorage(db, &v1.User{Name: "lack_rename"})
	out, err = s.XXFindOne(ctx)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(out)

	fmt.Println("SoftDelete ==============>")
	s = v1.NewUserStorage(db, &v1.User{Id: "1"})
	err = s.XXDelete(ctx, true)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Delete ==============>")
	s = v1.NewUserStorage(db, &v1.User{Id: "1"})
	err = s.XXDelete(ctx, false)
	if err != nil {
		log.Fatal(err)
	}
}
```
事务支持
```go
func getDB() (*gorm.DB, error) {

	dsn := `your dns`
	db, err := gorm.Open(sqlite.Open("dao.db"), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}
	return db, nil
}

func TestRegisterCore(t *testing.T) {
	db, err := getDB()
	if err != nil {
		t.Fatalf("get db: %v", err)
	}

	ctx := context.TODO()
	tx := db.Begin()

	// TODO: 

	tx.Commit()
}
```

## 语法解析
`protoc-gen-dao` 通过解析 `protobuf` 中的注释来生成代码。repeated, map, message 字段会生成新的结构体，在数据库中存储格式为 json。
每个带`+gen:dao`注释的 message 会生成 *Schema 结构体，并生成对应的 CURD 方法。
```golang
// 注册 User 相应的数据库表
func (s *UserStorage) AutoMigrate() error 
// 分页查询，等同 FindAll 和 Count
func (s *UserStorage) XXFindPage(ctx context.Context, page, size int) ([]*User, int64, error) 
// 查询所有符合的记录
func (s *UserStorage) XXFindAll(ctx context.Context) ([]*User, error) 
// 查询符合的记录总量
func (s *UserStorage) Count(ctx context.Context) (int64, error)
// 查询首条符合的记录
func (s *UserStorage) XXFindOne(ctx context.Context) (*User, error)
// 插入一条记录
func (s *UserStorage) XXCreate(ctx context.Context) (*User, error) 
// 更新记录
func (s *UserStorage) XXUpdates(ctx context.Context) (*User, error)
// 软删除
func (s *UserStorage) XXDelete(ctx context.Context, soft) error 
```

### 类型转化

slice、map、message 自动生成实现 driver.Valuer 接口的类型
```protobuf
repeated string following = 3;
```
生成
```golang
type UserFollowing []string

// Value return json value, implement driver.Valuer interface
func (m UserFollowing) Value() (driver.Value, error) {
	if len(m) == 0 {
		return nil, nil
	}
	b, err := _go.Marshal(m)
	return string(b), err
}

// Scan scan value into Jsonb, implements sql.Scanner interface
func (m *UserFollowing) Scan(value interface{}) error {
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return errors.New(fmt.Sprint("Failed to unmarshal JSONB value:", value))
	}

	return _go.Unmarshal(bytes, &m)
}

func (m *UserFollowing) DaoDataType() string {
	return "json"
}
```
```protobuf
map<string, string> tags = 4;
```
生成
```golang
type UserTags map[string]string

// Value return json value, implement driver.Valuer interface
func (m UserTags) Value() (driver.Value, error) {
	if len(m) == 0 {
		return nil, nil
	}
	b, err := _go.Marshal(m)
	return string(b), err
}

// Scan scan value into Jsonb, implements sql.Scanner interface
func (m *UserTags) Scan(value interface{}) error {
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return errors.New(fmt.Sprint("Failed to unmarshal JSONB value:", value))
	}

	return _go.Unmarshal(bytes, &m)
}

func (m *UserFollowing) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	return dao.GetGormDBDataType(db, field)
}
```
```protobuf
Other other = 5;
```
生成
```golang
type UserOther Other

// Value return json value, implement driver.Valuer interface
func (m *UserOther) Value() (driver.Value, error) {
	if m == nil {
		return nil, nil
	}
	b, err := _go.Marshal(m)
	return string(b), err
}

// Scan scan value into Jsonb, implements sql.Scanner interface
func (m *UserOther) Scan(value interface{}) error {
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return errors.New(fmt.Sprint("Failed to unmarshal JSONB value:", value))
	}

	return _go.Unmarshal(bytes, &m)
}

func (m *UserFollowing) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	return dao.GetGormDBDataType(db, field)
}
```

### JSON 支持
`protoc-gen-dao` 将 slice、map 和 message 类型的字段转化为JSON格式并存储到数据库中，同时 Dao 支持通过 JSON 来作为查询条件。以下是JSON格式查询的条件
```golang
    // slice 格式，查询slice包含指定项的记录
    if len(m.Following) != 0 {
		for _, item := range m.Following {
			expr, query := dao.JSONQuery("following").Contains(tx, item)
			s.joins = append(s.joins, query)
			exprs = append(exprs, expr)
		}
	}
    // map 格式，查询kv符合条件的记录，key 类型必须为 string
	if m.Tags != nil {
		for k, v := range m.Tags {
			exprs = append(exprs, dao.JSONQuery("tags").Equals(v, k))
		}
	}
    // struct 格式，精确查询 JSON 
    // 支持两种方式:
    //  * 当传入 key 的值为空，查询对应 JSON key 是否存在
    //  * 当传入 key 为确定值时，查询对应 JSON key 是否等于对应的值
	if m.Other != nil {
		for k, v := range dao.FieldPatch(m.Other) {
			if v == nil {
				exprs = append(exprs, dao.JSONQuery("other").HasKey(strings.Split(k, ".")...))
			} else {
				exprs = append(exprs, dao.JSONQuery("other").Equals(v, strings.Split(k, ".")...))
			}
		}
	}
```
> 注: 如果默认数据库选择 Sqlite3 时，默认不支持 json_each, json_extract 方法，需要添加 -tags 选项。 `go build -tags JSON1 main.go`

### 语法规则
有效的注释有以下的规则:
- 注释必须以 `+gen` 作为开头
- 注释的内容必须紧贴对应的字段，中间不能有空行
- 支持多行注释，也可以将多行合并成一行，并用 `;` 作为分隔符
- 只有带 `+gen:dao` 注释的 message 才会生成 CURD 代码

### 语法支持
#### 代码输出路径
`protoc-gen-dao` 支持将CURD代码输出到指定路径
```protobuf
// +dao:output=github.com/vine-io/vine/testdata/db/dao;dao
syntax = "protoc"
...
```
使用 `+dao:output=`为开头，写在 protobuf 文件头部，指定生成的路径(对应$GOPATH)和生成 package 名称。

#### message 支持
message 支持以下注释:
```protobuf
// +gen:dao  => 只有标识该注释的 message 才会生成 CURD 代码
// +gen:object => 会生成 storage.Storage 接口方法
```

#### field 支持
```protobuf
// +gen:pk   => 指定字段为主键(必须), 可以是 string 和 数字, 当 int 类型时自增 
//              当多个 PK 字段存在时，默认选择第一个。
// +gen:inline => 只能用在 message field 中，将 message 的字段直接解析为父 message 的字段
// +gen:daoInject => 注入额外的数据库约束，详细请看 https://gorm.io/zh_CN/docs/models.html
...
```
