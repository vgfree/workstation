package main
import (
	"fmt"
	"tour/pic"
)

func Pic(dx, dy int) [][]uint8 {

}

func main() {

	s := make([]int, 5)
	for i := 0; i < len(s); i++ {
		s[i] = []int(2^i, 5^i, 10^i, 20^i)
	}

	pic.Show(Pic)

}















