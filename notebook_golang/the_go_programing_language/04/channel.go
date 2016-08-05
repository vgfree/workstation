package main

import (
	"fmt"
)

func Count(ch chan int, value int) {
	fmt.Println("counting", value)
	ch <- value
}

func main() {
	chs := make([]chan int, 10)
	for i := 0; i < 10; i++ {
		chs[i] = make(chan int)
		go Count(chs[i], i)
		fmt.Println(i)
	}

	for _, ch := range(chs) {
		fmt.Println("*****")
		val := <-ch
		fmt.Println("value:", val)
	}
}
