package main
import (
	"fmt"
	"math"
)

type Vertex struct {
	X, Y float64
}
// 方法名为 Abs , v 为方法接收者
func (v *Vertex) Abs() float64 {
	return math.Sqrt(v.X * v.X + v.Y * v.Y)
}
// 对任意类型都可以定义方法
type MyFloat float64

func (f MyFloat) Abs1() float64 {
	if f < 0 {
		return float64(-f)
	}
	return float64(f)
}
// 接收者为指针的方法
func (v *Vertex) Scale(f float64) {
	v.X = v.X * f
	v.Y = v.Y * f
}

func (v *Vertex) Abs2() float64 {
	return math.Sqrt(v.X * v.X + v.Y * v.Y)
}

func main() {
	v := &Vertex{3, 4}
	fmt.Println(v.Abs())

	f := MyFloat(-math.Sqrt2)
	fmt.Println(f.Abs1())

	v.Scale(5)
	fmt.Println(v, v.Abs2())
}


















