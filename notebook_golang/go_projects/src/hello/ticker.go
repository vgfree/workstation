package main

import (
	"fmt"
	"time"
)
// 打点器在固定的时间间隔重复执行
func main() {
	ticker := time.NewTicker(time.Millisecond * 500)
	go func() {
		// 一个通道用来发送数据. 迭代使其每500ms发送一次值
		for t := range ticker.C {
			fmt.Println("Tick out", t)
		}
	}()

	time.Sleep(time.Millisecond * 1600)
	timer := time.NewTimer(time.Millisecond * 1500)
	<-timer.C

	ticker.Stop()
	fmt.Println("Ticker stopped")
}
