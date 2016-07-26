package main
import (
	"fmt"
	"bitbucket.org/mikespook/go-tour-zh/tree"
//	"tour/tree"
)

type Tree struct {
	Left *Tree
	Value int
	Right *Tree
}

func Walk(t *tree.Tree, ch chan int) {
	if t != nil {
		Walk(t.Left, ch)
		ch <- t.Value
		Walk(t.Right, ch)
	}
}

func Same(t1, t2 *tree.Tree) bool {
	ch1 := make(chan int, 10)
	go Walk(t1, ch1)

	ch2 := make(chan int, 10)
	go Walk(t2, ch2)

	for i := 0; i < 10; i++ {
		if <- ch1 != <-ch2 {
			return false
		}
	}
	return true
}

func main() {
	fmt.Println(Same(tree.New(1), tree.New(1)))
}
