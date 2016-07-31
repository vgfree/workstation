package main

import (
	"fmt"
)

func main() {
	// make[key-type]val-type
	m := make(map[string]int)
	m["k1"] = 7
	m["k2"] = 10
	fmt.Println("map:", m)

	v1 := m["k1"]
	fmt.Println("v1:", v1)
	fmt.Println("len:", len(m))

	delete(m, "k2")
	fmt.Println("map:", m)

	// 可选的第二个返回值指示这个键是否在map中
	_, prs := m["k2"]
	fmt.Println("prs:", prs)

	n := map[string]int{"foo":1, "bar":2}
	fmt.Println("map:", n)
}
