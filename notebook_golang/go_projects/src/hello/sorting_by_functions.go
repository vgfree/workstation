package main

import (
	"fmt"
	"sort"
)

type ByLength []string

// Len() Swap() Less() 三个方法是必需的
func (s ByLength) Len() int {
	return len(s)
}

func (s ByLength) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}
// 按照长度增加来排序
func (s ByLength) Less(i, j int) bool {
	return len(s[i]) < len(s[j])
}

func main() {
	fruits := []string{"peach", "banana", "kiwi"}
	sort.Sort(ByLength(fruits))

	fmt.Println(fruits)
}
