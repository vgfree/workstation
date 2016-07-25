package main

import "fmt"

type Vertex struct {
	Lat, Long float64
}

var m map[string]Vertex

// map 键名是必需的
var n = map[string]Vertex{
	"Bell Labs": Vertex{
		40.68433, 74.39967,
	},
	"Google": Vertex{
		37.42202, -122.08408,
	},
}
// 如果顶层类型只有类型名的话, 可以在文法的元素中省略键名
var o = map[string]Vertex{
	"china": { 40.68433, 74.39967 },
	"usa": { 37.42202, -122.08408 },
}

// map 映射键到值
func main() {
	m = make(map[string]Vertex)
	m["Bell Labs"] = Vertex{
		40.68433, 74.39967,
	}

	fmt.Println(m["Bell Labs"])

	fmt.Println(n)

	fmt.Println(o)

	// 修改map
	r := make(map[string]int)
	// 加入/修改元素
	r["Answer"] = 42
	fmt.Println("The value:", r["Answer"])

	r["Answer"] = 50
	fmt.Println("The value:", r["Answer"])
	// 删除元素
	delete(r, "Answer")
	fmt.Println("The value:", r["Answer"])
	// 通过双赋值检测某个键存在
	v, ok := r["Answer"]
	fmt.Println("The value:", v, "Present?", ok)


}
