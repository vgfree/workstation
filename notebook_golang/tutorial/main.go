package main
import (
	"fmt"
	"math/cmplx"
	"math"
)

func add(x , y int) int {
	return x + y
}

func swap(x, y string) (string, string) {
	return y, x
}

func split(sum int) (x, y int) {
	x = sum * 4 / 9
	y = sum - x
	return
}

var x, y, z int = 1, 2, 3
var c, python, java = true, false, "no!"

// 常量定义
const Pi = 3.14

// 数值常量
const (
	Big = 100
	Small = 1
)

func needInt(x int) int { return x * 10 + 1 }
func needFloat(x float64) float64 { return x * 0.1 }

// if 语句
func sqrt(x float64) string {
	if x < 0 {
		return sqrt(-x) + "i"
	}
	return fmt.Sprint(math.Sqrt(x))
}

func pow(x, n, lim float64) float64 {
	if v := math.Pow(x, n); v < lim {
		return v
	} else {
		fmt.Printf("%g >= %g\n", v, lim)
	}
	// 在此处 v 就不能用了
	return lim
}

// 基本类型
var (
	ToBe bool = false
	MaxInt uint64 = 1<<64 - 1
	m complex128 = cmplx.Sqrt(-5 + 12i)
)

// 结构体
type Vertex struct {
	X int
	Y int
}


func main() {
	fmt.Println("Happy", math.Pi, "Day")
	fmt.Printf("Now you have %g problems.\n", math.Nextafter(2, 3))
	fmt.Println(add(42, 13))

	a, b := swap("hello", "world")
	fmt.Println(a, b)

	fmt.Println(split(17))

	fmt.Println(x, y, z, c, python, java)

	// := 只能用在函数内, 可以替代var定义
	china, usa, russia := true, false, "no!"
	fmt.Println(china, usa, russia)

	const World = "世界"
	fmt.Println("Hello", World)
	fmt.Println("Happy", Pi, "Day")

	const Truth = true
	fmt.Println("Go rules?", Truth)

	fmt.Println(needInt(Small))
	fmt.Println(needFloat(Small))
	fmt.Println(needFloat(Big))
	fmt.Println(needInt(Big))

	// 只有一种循环结构
	sum := 0
	for i := 0; i < 10; i++ {
		sum += i
	}
	fmt.Println(sum)
	// 前置/后置语句为空
	sum1 := 1
	for ; sum1 < 1000; {
		sum1 += sum1
	}
	fmt.Println(sum1)
	// 继续省略 ;
	sum2 := 1
	for sum2 < 1000 {
		sum2 += sum2
	}
	fmt.Println(sum2)
	// 死循环
	//for {}

	fmt.Println(sqrt(2), sqrt(-4))

	fmt.Println(
		pow(3, 2, 10),
		pow(3, 3, 20),
	)

	// 基本类型
	const f = "%T(%v)\n"
	fmt.Printf(f, ToBe, ToBe)
	fmt.Printf(f, MaxInt, MaxInt)
	fmt.Printf(f, m, m)

	// 结构体
	fmt.Println(Vertex{1, 2})

	v := Vertex{1, 2}
	v.X = 4
	fmt.Println(v.X)

	// 指针
	p := Vertex{1, 2}
	q := &p
	q.X = 1e9
	fmt.Println(p)


}
