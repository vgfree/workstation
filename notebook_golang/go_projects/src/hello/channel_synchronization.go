// 使用通道来同步Go协程间的执行状态
// 使用阻塞接收的方式来等待一个go协程的结束

package main

import (
	"fmt"
	"time"
)

func worker(done chan bool) {
	fmt.Println("working ...")
	time.Sleep(time.Second)
	fmt.Println("done")

	done <- true
}

func main() {
	done := make(chan bool, 1)
	go worker(done)

	// 程序在接收到通道中worker发出的通知前一直阻塞
	<-done
}
