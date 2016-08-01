package main

import "fmt"

func main() {
	jobs := make(chan int, 5)
	done := make(chan bool)

	go func() {
		for {
			// channel中为空则返回false
			j, more := <-jobs
			if more {
				fmt.Println("received job", j)
			} else {
				fmt.Println("received all jobs")
				done <- true
				return
			}
		}
	}()

	for j := 1; j <= 3; j++ {
		jobs <- j
		fmt.Println("send job", j)
	}
	// 通道可以关闭
	close(jobs)
	fmt.Println("send all jobs")
	// 通道同步方式等待任务结束
	<-done
}
