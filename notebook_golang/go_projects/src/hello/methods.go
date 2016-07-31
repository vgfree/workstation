package main

import (
	"fmt"
)

type rect struct {
	width, height int
}

// area方法  rect接收器类型
// 指针类型接收器
func (r *rect) area() int {
	return r.width * r.height
}
// perim 方法
// 值类型接收器
func (r rect) perim() int {
	return 2 * r.width + 2 * r.height
}

func main() {
	r := rect{width: 10, height: 5}

	fmt.Println("area:", r.area())
	fmt.Println("perim:", r.perim())

	// 使用指针调用来避免在方法调用时产生一个拷贝
	rp := &r
	fmt.Println("area:", rp.area())
	fmt.Println("perim:", rp.perim())
}


