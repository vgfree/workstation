package main

import (
	"fmt"
	"errors"
)

func f1(arg int) (int, error) {
	if arg == 42 {
		// 构造一个使用给定的错误信息的基本error值
		return -1, errors.New("Can't work with 42")
	}
	return arg + 3, nil
}

type argError struct {
	arg int
	prod string
}

// 通过实现Error方法来自定义error类型
// 此处不用指针, 后面作相应改变后, 结果不变!!!
func (e *argError) Error() string {
	return fmt.Sprintf("%d - %s", e.arg, e.prod)
}

func f2(arg int) (int, error) {
	if arg == 42 {
		// 使用&argError语法来建立一个新的结构体.并提供arg和prob字段的值
		return -1, &argError{arg, "can't work with it"}
	}
	return arg + 3, nil
}

func main() {
	for _, i := range []int{7, 42} {
		if r, e := f1(i); e != nil {
			fmt.Println("f1 failed:", e)
		} else {
			fmt.Println("f1 worked:", r)
		}
	}

	for _, i := range []int{7, 42} {
		if r, e := f2(i); e != nil {
			fmt.Println("f1 failed:", e)
		} else {
			fmt.Println("f1 worked:", r)
		}
	}

	_, e := f2(42)
	// 类型断言
	if ae, ok := e.(*argError); ok {
		 fmt.Println(ae.arg)
		 fmt.Println(ae.prod)
	}

}
