package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	sum := 0
	// range 可以迭代slice, array
	for _, num := range nums {
		sum += num
	}
	fmt.Println("sum:", sum)

	for i, num := range nums {
		if num == 3 {
			fmt.Println("index:", i)
		}
	}

	// range 可以迭代map
	kvs := map[string]string{"a":"apple", "b":"banana"}
	for k, v := range kvs {
		fmt.Println("%s -> %s", k, v)
	}
	// range 可以迭代字符串unicode编码
	for i, c := range "abc" {
		fmt.Println(i, c)
	}
}
