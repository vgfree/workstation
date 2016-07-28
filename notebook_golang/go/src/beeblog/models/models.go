package models

import (
//	"os"
//	"path"
	"time"
//	"github.com/astaxie/beego"
//	"github.com/Unknown/com"
//	_ "github.com/go-sql-driver/mysql"
	_ "github.com/Go-SQL-Driver/MySQL"
	"github.com/astaxie/beego/orm"
//	_ "github.com/mattn/go-sqlite3" // 下划线表示只进行初始化函数, 不进行其他函数调用
)

const (
	_DB_NAME = "data/beeblog.db"
	_MYSQL_DRIVER = "mysql"
)

// 模型
type Category struct {
	Id int64
	Title string
	Created time.Time `orm:"index"` // orm 标识符, 表示只有orm会读
	Views int64 `orm:"index"`
	TopicTime time.Time `orm."index"`
	TopicCount int64
	TopicLastUserId int64 // 最后访问用户
}

type Topic struct {
	Id int64
	Uid int64
	Title string
	Content string `orm:"size(5000)"`
	Attachment string
	Created time.Time `orm:"index"`
	Updated time.Time `orm:"index"`
	Views int64 `orm:"index"`
	Author string
	ReplyTime time.Time `orm:"index"`
	ReplyCount int64
	ReplyLastUserId int64
}

func RegisterDB() {
	// 检查数据库是否存在
//	if !com.IsExist(_DB_NAME) {
//	os.MkdirAll(path.Dir(_DB_NAME), os.ModePerm)
//	os.Create(_DB_NAME)

	// 注册model
	orm.RegisterModel(new(Category), new(Topic)) // 模型注册
	orm.RegisterDriver("mysql", orm.DR_MySQL)

//	orm.RegisterDriver(_MYSQL_DRIVER, orm.DR_MySQL) // 初始化驱动
	orm.RegisterDataBase("default", _MYSQL_DRIVER, _DB_NAME, 10) // 创建默认数据库
}






