package main

import (
	"fmt"
)

func f(from string) {
	for i := 0; i < 10; i++ {
		fmt.Println(from, ":", i)
	}
}

func main() {
	// 阻塞式调用
	f("direct")
	// 启动协程
	go f("goroutine")
	go f("louis")
	// 为匿名函数启动一个协程
	go func(msg string) {
		fmt.Println(msg)
	}("going")
	// 以上三个go协程在独立的go协程中异步运行
	var input string
	fmt.Scanln(&input)
	fmt.Println("done")
}
