package main

import "fmt"

type Requset struct {
	Method string "method"
	Params string "params"
}

func main() {
	var s Requset
	s.Method = "louis"
	fmt.Println(s.Method, s.Params)
}
