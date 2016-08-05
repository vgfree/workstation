package main

import (
	"fmt"
	"sync"
	"time"
)

var a string
var once sync.Once

func setup() {
	a = "hello, world"
}

func doprint() {
	once.Do(setup)
	fmt.Println(a)
}

func twoprint() {
	go doprint()
	go doprint()
}

func main() {
	twoprint()
	time.Sleep(time.Second)
}
