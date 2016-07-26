package main
import (
	"fmt"
)

func Cbrt(x complex128) complex128 {
	var z complex128 = 2
	for i := 0; i < 10; i++ {
		z = z - (z * z * z - x) / (3 * z * z)
	}

	return z
}

func main() {
	fmt.Println(Cbrt(10))
}















