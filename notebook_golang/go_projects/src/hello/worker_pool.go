package main

import (
	"fmt"
	"time"
)

// 通过jobs通道接收任务,通过results发送对应的结果
func worker(id int, jobs <-chan int, results chan<- int) {
	for j := range jobs {
		fmt.Println("worker", id, "processing job", j)
		time.Sleep(time.Second)
		results <- j * 2
	}
}

func main() {
	jobs := make(chan int, 100)
	results := make(chan int, 100)

	for w := 1; w <= 3; w++ {
		go worker(w, jobs, results)
	}

	for j := 1; j <= 9; j++ {
		jobs <- j
	}

	close(jobs)
	// 收集任务的返回值
	for a := 1; a <= 9; a++ {
		<-results
	}
}
