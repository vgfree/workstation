package main

import (
	"fmt"
	"time"
	_ "redis/routers"
	"github.com/astaxie/beego"
	"github.com/astaxie/beego/cache"
	_ "github.com/astaxie/beego/cache/redis"
)

func main() {
	red, err := cache.NewCache("redis", `{"conn":"127.0.0.1:6379", "key":"beecacheRedis"}`)
	if err != nil {
		fmt.Println(err)
	}

	red.Put("name", "louis", time.Second * 5)

	re := red.Get("name")

	fmt.Printf("%T", re)

	fmt.Println(string(re.([]byte)))

	beego.Run()
}

