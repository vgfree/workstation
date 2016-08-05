package main
import (
	"fmt"
	"time"
)

func fibonacci(c, quit chan int) {
	x, y := 0, 1
	for {
		// 使得一个goroutine在多个通讯操作上等待
		// select 会阻塞,直到条件分之中的某个可以继续执行,
		// 当多个都准备好时, 会随机选一个
		select {
		case c <- x:
			x, y = y, x + y
		case <- quit:
			fmt.Println("quit")
			return
		}
	}
}

func main() {
	c := make(chan int)
	quit := make(chan int)
	go func() {
		for i := 0; i < 10; i++ {
			fmt.Println(<-c)
		}
		quit <- 0
	}()

	fibonacci(c, quit)

	fmt.Println("\n")

	tick := time.Tick(1e8)
	boom := time.After(5e8)
	for {
		select {
		case <- tick:
			fmt.Println("tick")
		case <- boom:
			fmt.Println("BOOM!")
			return
		// select 中其他分支都没有准备好时, 执行default分支
		default:
			fmt.Println(" .")
			time.Sleep(5e7)
		}
	}
}
