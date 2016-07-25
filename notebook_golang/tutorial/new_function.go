package main

import "fmt"

type Vertex struct {
	X, Y int
}

func main() {
	// new()分配一个零初始化的值, 并返回指向它的指针
	v := new(Vertex)
	fmt.Println(v)

	v.X, v.Y = 11, 9
	fmt.Println(v)
}











