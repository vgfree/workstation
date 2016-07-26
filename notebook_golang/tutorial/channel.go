package main
import "fmt"

func sum(a []int, ch chan int) {
	sum := 0
	for _, v := range a {
		sum += v
	}
	ch <- sum	// send sum to c
}

func main() {
	a := []int{7, 2, 8, -9, 4, 0}

	// channel是有类型的管道, channel在使用前必须创建
	// 默认情况下,在另一端准备好之前, 发送和接受都会阻塞
	ch := make(chan int)
	go sum(a[:len(a) / 2], ch)
	go sum(a[len(a) / 2:], ch)
	x, y := <-ch, <-ch	// 从c中接收, <-- channel操作符

	fmt.Println(x, y, x + y)

	// 缓冲channel, 缓冲区满的时候会阻塞
	c := make(chan int, 2)
	c <- 1
	c <- 2
	//c <- 3
	fmt.Println(<-c)
	fmt.Println(<-c)


}









