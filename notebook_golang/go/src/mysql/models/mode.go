package models

import (
	"github.com/astaxie/beego/orm"
	"time"
	_"github.com/mattn/go-sqlite3"
)

type Store struct {
	Id int64
	Title string
	Created time.Time
	Views int64 `orm:"index"`
	TopicTime time.Time `orm:"index"`
	TopicCount int64
	TopicLastUserId int64
}

type Customer struct {
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
	orm.RegisterModel(new(Store), new(Customer))
	orm.RegisterDriver("mysql", orm.DR_Sqlite)
	orm.RegisterDataBase("default", "mysql", "root@/app?charset=utf8")

}







