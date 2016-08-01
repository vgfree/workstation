package main

import (
	"fmt"
	"time"
)

func main() {
	c1 := make(chan string, 3)
	c2 := make(chan string, 3)

	go func() {
		time.Sleep(time.Second * 2)
		c1 <- "one"
	}()

	go func() {
		time.Sleep(time.Second * 1)
		c2 <- "two"
	}()

	for i := 0; i < 2; i++ {
		// 通道选择器同时等待多个通道操作
		select {
		case msg1 := <-c1:
			fmt.Println("recived", msg1)
		case msg2 := <-c2:
			fmt.Println("recived", msg2)
		}
	}
}

