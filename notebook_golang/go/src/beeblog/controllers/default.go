package controllers

import (
	"github.com/astaxie/beego"
)

type MainController struct {
	beego.Controller
}

func (c *MainController) Get() {
	c.Data["Website"] = "beego.me"
	c.Data["Email"] = "astaxie@gmail.com"
	c.TplName = "home.html"
	c.Data["TrueCond"] = true
	c.Data["FalseCond"] = false

	// 结构体变量
	type u struct {
		Name string
		Age int
		Sex string
	}

	user := &u {
		Name:"Louis",
		Age:20,
		Sex:"Male",
	}

	c.Data["User"] = user
	// 数组
	nums := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 0}
	c.Data["Nums"] = nums
	// 模版变量
	c.Data["TplVar"] = "hey guys"
	// str2html
	c.Data["Html"] = "<div>hello beego</div>"
	c.Data["Pipe"] = "<div>hello beego</div>"

}
