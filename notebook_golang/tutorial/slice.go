package main
import "fmt"

func main() {
	// slice 指向数组的值,并且同时包含长度信息
	// 元素类型为int的slice
	p := []int{2, 3, 5, 7, 11, 13}
	fmt.Println("p == ", p)

	for i := 0; i < len(p); i++ {
		fmt.Printf("p[%d] == %d\n", i, p[i])
	}
}
