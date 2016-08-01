package main

import (
	"fmt"
	"os"
)

func main() {
	f := createFile("./defer.txt")
	// defer会在所在的封闭函数执行完毕后再执行
	// 确保一个函数调用在程序执行结束前执行
	defer closeFile(f)
	writeFile(f)
}

func createFile(p string) *os.File {
	fmt.Println("creating")
	f, err := os.Create(p)
	if err != nil {
		panic(err)
	}
	return f
}

func writeFile(f *os.File) {
	fmt.Println("writing")
	fmt.Fprintf(f, "data")
}

func closeFile(f *os.File) {
	fmt.Println("closing")
	f.Close()
}
