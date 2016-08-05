package main

import "fmt"

func main() {
	ch := make(chan int, 10)
	for i := 0; i < 10; i++ {
		ch <- i
	}

	for i := range ch {
		fmt.Println(i)
	}
}
