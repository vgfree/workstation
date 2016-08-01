package main

import (
	"fmt"
)

func main() {
	// 创建新的通道(无缓存)
	messages := make(chan string)
	go func() {messages <- "ping"}()

	msg := <-messages

	fmt.Println(msg)
}
