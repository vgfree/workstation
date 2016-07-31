package main

import (
	"fmt"
)

type person struct {
	name string
	age int
}

func main() {
	fmt.Println(person{"Bob", 20})

	fmt.Println(person{name: "Louis", age: 20})

	fmt.Println(person{name: "Shana"})
	// &{Asuka 20} 结构体指针
	fmt.Println(&person{name: "Asuka", age: 20})

	s := person{name: "Miku", age: 16}
	fmt.Println(s.name)

	sp := &s
	fmt.Println(sp.age)

	sp.age = 50
	fmt.Println(sp.age)
}
