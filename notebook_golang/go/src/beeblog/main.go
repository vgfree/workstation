package main

import (
	_ "beeblog/routers"
	"github.com/astaxie/beego"
	"beeblog/controllers"
	"beeblog/models"
	"github.com/astaxie/beego/orm"
	//_"github.com/go-sql-driver/mysql"
	_"github.com/Go-SQL-Driver/MySQL"
)

func init() {
	models.RegisterDB()
}

func main() {
	orm.Debug = true
	orm.RunSyncdb("default", false, true)
	beego.Router("/", &controllers.MainController{})
	beego.Run()
}

