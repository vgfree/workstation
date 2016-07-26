package main
import (
	"fmt"
)

func fibonacci() func() int {
	var ln_prev, ln_current, ln_next int
	ln_current = 1
	return func() int {
		ln_next = ln_current + ln_prev
		ln_prev = ln_current
		ln_current = ln_next
		return ln_prev
	}
}

func main() {
	f := fibonacci()
	for i := 0; i < 10; i++ {
		fmt.Println(f())
	}
}















