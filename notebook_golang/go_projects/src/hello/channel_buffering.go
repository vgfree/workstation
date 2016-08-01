package main

import (
	"fmt"
)

func main() {
	// 带缓存的通道
	messages := make(chan string, 2)
	messages <- "louis"
	messages <- "shana"

	fmt.Println(<-messages)
	fmt.Println(<-messages)
}
