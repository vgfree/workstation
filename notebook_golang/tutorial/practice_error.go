package main
import "fmt"

type ErrNegativeSqrt float64



func Sqrt(f float64) (float64, error) {
	return 0, nil
}

func main() {
	fmt.Println(Sqrt(2))
	fmt.Println(Sqrt(-2))
}







