package main

import (
	"fmt"
	"time"
)

func main() {
	timer1 := time.NewTimer(time.Second * 2)
	// 定时器将提供一个用于通知的通道,
	// 定时器的通道C在发送失效的值之前将一直阻塞
	<-timer1.C
	fmt.Println("Timer 1 expired")

	timer2 := time.NewTimer(time.Second)
	go func() {
		<-timer2.C
		fmt.Println("Timer2 expired")
	}()
	// 定时器可以取消
	// Sleep不可以取消, 单传的等待可以使用Sleep
	stop2 := timer2.Stop()
	if stop2 {
		fmt.Println("Timer 2 stopped")
	}
}
