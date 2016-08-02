package qsort

func quickSort (values []int, left, right int) {
	temp := values[left]
	p := left
	i, j := left, right

	for i <= j {
		// 从右开始向左寻找小与temp的数
		for j >= p && values[j] >= temp {
			j--
		}
		// 当找到了这个值时执行填坑操作,同时下一次操作从新的位置开始
		if j >= p {
			values[p] = values[j]
			p = j
		}
		// 从左开始寻找大于temp的操作
		if values[i] <= temp && i <= p {
			i++
		}
		// 找到了就执行填坑操作
		if i <= p {
			values[p] = values[i]
			p = i
		}
	}
	values[p] = temp

	if p - left > 1 {
		quickSort(values, left, p - 1)
	}
	if right - p > 1 {
		quickSort(values, p + 1, right)
	}
}

func QuickSort(values []int) {
	quickSort(values, 0, len(values) - 1)
}
