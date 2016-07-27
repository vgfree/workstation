package main

import (
	"github.com/astaxie/beego"	// 会初始化一个beeAPP的应用和一些参数
)
// 定义Controller, 匿名包含beego.Controller
// 框架中Controller拥有很多方法: Get Post Delete Put, 分别对应用户请求类型
type MainController struct {
	beego.Controller
}
// 重写继承的Get函数
func (this *MainController) Get() {
	this.Ctx.WriteString("hello world")
}

func main() {
	// 注册路由, 请求到来时, 调用相应的Controller
	beego.Router("/", &MainController{})	// 路径 + Controller指针
	beego.Run()	// 将初始化的BeeAPP开启起来
}
