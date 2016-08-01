package main

import (
	"fmt"
)

func main() {
	queue := make(chan string, 2)
	queue <- "one"
	queue <- "two"
	close(queue)
	// channel关闭后仍然可以接受其中的内容
	// 如果没有close,循环将会阻塞执行,等待接收第三个值
	for elem := range queue {
		fmt.Println(elem)
	}
}
