package main

import "os"

func main() {
	// 出乎意料的错误产生
	panic("a problem")

	_, err := os.Create("/tmp/file")
	if err != nil {
		panic(err)
	}
}
