package main

import (
	"fmt"
	"time"
)

func main() {
	// 将请求发送给一个相同的通道
	requests := make(chan int, 5)
	for i := 1; i <= 5; i++ {
		requests <- i
	}
	close(requests)
	// limiter每200ms接收一个值, 这个是速率限制任务中的管理器
	limiter := time.Tick(time.Millisecond * 200)
	// 通过在每次请求前阻塞limiter的一个接收,来达到限制速率的目的
	for req := range requests {
		<- limiter
		fmt.Println("request", req, time.Now())
	}

	// 临时进行速率限制
	burstyLimiter := make(chan time.Time, 3)

	// channel前三次添加的时间值几乎是一样的,
	// 所以后续处理前三个是几乎同时处理
	for i := 0; i < 3; i++ {
		burstyLimiter <- time.Now()
	}

	// 从第四个开始channel中每200ms添加一个新值,即每200ms执行一个
	go func() {
		// 每200ms添加一个新的值到burstyLimiter中,直到通道满
		for t := range time.Tick(time.Millisecond * 200) {
			burstyLimiter <- t
		}
	}()

	burstyRequests := make(chan int, 5)
	for i := 1; i <= 5; i++ {
		 burstyRequests <- i
	}
	close(burstyRequests)
	for req := range burstyRequests {
		<-burstyLimiter
		fmt.Println("request", req, time.Now())
	}
}
