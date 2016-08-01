package main

import (
	"fmt"
)

func main() {
	messages := make(chan string)
	signals := make(chan bool)

	// 非阻塞接收
	select {
	case msg := <-messages:
		fmt.Println("received message", msg)
	default:
		fmt.Println("no message received")
	}

	msg := "hi"
	select {
	case messages <-msg:
		fmt.Println("sent message", msg)
	default:
		fmt.Println("no message sent")
	}

	// 使用多个case子句实现一个多路的非阻塞选择器
	select {
	case msg := <-messages:
		fmt.Println("received message", msg)
	case sig := <-signals:
		fmt.Println("received signal", sig)
	default:
		fmt.Println("no activity")
	}
}
