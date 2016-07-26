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

	// slice 支持切片
	fmt.Println("p[1:4] == ", p[1:4])
	fmt.Println("p[:3] == ", p[:3])
	fmt.Println("p[4:] == ", p[4:])

	// make 创建slice, 这会分配一个零长度的数组并返回一个slice指向这个数组
	a := make([]int, 5)
	printSlice("a", a)

	b := make([]int, 0, 5)
	printSlice("b", b)

	c := b[:2]
	printSlice("c", c)

	d := c[2:5]
	printSlice("d", d)

	// slice 零值为nil, 长度和容量都为0
	var z []int
	fmt.Println(z, len(z), cap(z))
	if z == nil {
		fmt.Println("nil!")
	}
}

func printSlice(s string, x[]int) {
	fmt.Printf("%s, len = %d, cap = %d, %v \n", s, len(x), cap(x), x)
}







