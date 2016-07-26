package main
import (
	"fmt"
	"time"
)

type MyError struct {
	When time.Time
	What string
}

// 这个看起来没用上, 实际上应该定义了返回error的方法
func (e *MyError) Error() string {
	return fmt.Sprintf("at %v, %s", e.When, e.What)
}

func run() error {
	return &MyError {
		time.Now(),
		"it didn't work",
	}
}

func main() {
	if err := run(); err != nil {
		fmt.Println(err)
	}
}

/*
type error interface {
	Error() string
}
*/

























