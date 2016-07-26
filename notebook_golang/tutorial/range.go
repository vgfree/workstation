package main
import "fmt"

var p = []int{1, 2, 4, 8, 16, 32, 64, 128}

func main() {
	// range 可以对slice或map进行迭代循环
	for i, v := range p {
		fmt.Printf("2 ** %d = %d\n", i, v)
	}

	pow := make([]int, 10)
	for i := range pow {
		pow[i] = 1<<uint(i)
	}
	for _, value := range pow {
		fmt.Printf("%d\n", value)
	}
}
