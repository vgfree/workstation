
读取不同模式下配置参数的方法:
beego.AppConfig.String(“dev::mysqluser”)

对于自定义的参数，需使用beego.GetConfig(typ, key string)来获取指定runmode下的配
置，typ为参数类型，key为参数名

RESTful Controller 路由
固定路由
```conf
beego.Router("/", &controllers.MainController{})
beego.Router("/admin", &admin.UserController{})
beego.Router("/admin/index", &admin.ArticleController{})
beego.Router("/admin/addpkg", &admin.AddController{})
```

正则路由
```
beego.Router(“/api/?:id”, &controllers.RController{})
默认匹配 //匹配 /api/123 :id = 123 可以匹配/api/这个URL
...
在controller中获取方法格式
this.Ctx.Input.Param(":id")
```

自动路由


HTTP Method
```
*：包含以下所有的函数
get ：GET 请求
post ：POST 请求
put ：PUT 请求
delete ：DELETE 请求
patch ：PATCH 请求
options ：OPTIONS 请求
head ：HEAD 请求
```



