package main

import (
	"fmt"
	"time"
	"sync/atomic"
	"runtime"
)

func main() {
	var ops uint64 = 0
	for i := 0; i < 50; i++ {
		go func() {
			for {
				atomic.AddUint64(&ops, 1)
				// 允许其他协程运行,让出CPU时间片
				runtime.Gosched()
			}
		}()
	}
	time.Sleep(time.Second)
	// 取址的方式可以安全的获取ops值(其他协程还在运行更新操作)
	opsFinal := atomic.LoadUint64(&ops)
	fmt.Println("ops:", opsFinal)

}
