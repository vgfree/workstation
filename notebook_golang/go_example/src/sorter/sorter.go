package main

import (
	"io"
	"flag"
	"fmt"
	"bufio"
	"strconv"
	"os"
	"time"

	"sorter/algorithms/bubblesort"
	"sorter/algorithms/qsort"
)

// infile 是默认值
var infile *string = flag.String("i", "infile", "file containss values for sorting")
var outfile *string = flag.String("o", "outfile", "file to recieve sorted values")
var algorithm *string = flag.String("a", "qsort", "sort algorithm")

func readValues(infile string)(values []int, err error) {
	file, err := os.Open(infile)
	if err != nil {
		fmt.Println("failed to open the input file.", err)
		return
	}
	defer file.Close()

	// 创建一个默认大小的buffer
	br := bufio.NewReader(file)
	values = make([]int, 0)

	for {
		// 逐行读取数据,数据太长/找不到\n则isPrefix为true
		line, isPrefix, err1 := br.ReadLine()
		if err1 != nil {
			if err1 != io.EOF {
				err = err1
			}
			fmt.Println("err:", err)
			break
		}
		if isPrefix {
			fmt.Println("a too long line, seems unexpected.")
			return
		}
		// 转换字符数组为字符串
		str := string(line)
		fmt.Println(str)
		value, err1 := strconv.Atoi(str)
		if err1 != nil {
			err = err1
			return
		}
		values = append(values, value)
	}
	return
}

func writeValues(values []int, outfile string) error {
	file, err := os.Create(outfile)
	if err != nil {
		fmt.Println("failed to create the output file ", outfile)
		return err
	}

	defer file.Close()

	for _, value := range values {
		str := strconv.Itoa(value)
		file.WriteString(str + "\n")
	}
	return nil
}


func main() {
	// 解析命令行参数到定义的flag
	flag.Parse()

	if infile != nil {
		fmt.Println("infile =", *infile, "outfile =", *outfile, "algorithm =",
		*algorithm)
	}

	values, err := readValues(*infile)
	if err == nil {
		fmt.Println("Read values: ", values)
		t1 := time.Now()
		switch *algorithm {
		case "qsort":
			qsort.QuickSort(values)
		case "bubblesort":
			bubblesort.BubbleSort(values)
		default:
			fmt.Println("Sorting algorithm", *algorithm, "is either unknown or unsupported.")
		}
		t2 := time.Now()

		fmt.Println("The sorting process costs ", t2.Sub(t1), "to complete.")

		err = writeValues(values, *outfile)
		if err == nil {
			fmt.Println("write value successful")
		} else {
			fmt.Println(err)
		}
	} else {
		fmt.Println(err)
	}
}
