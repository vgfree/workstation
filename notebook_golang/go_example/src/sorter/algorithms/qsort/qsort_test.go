package qsort

import "testing"

func TestQuickSort1(t *testing.T) {
	values := []int{5, 1, 4, 3, 2}

	QuickSort(values)

	if values[0] != 1 || values[1] != 2 || values[2] != 3 || values[3] != 4 ||
	values[4] != 5 {
		t.Error("QuickSort failed. Got", values, "Expect 1 2 3 4 5")
	}
}

func TestQuickSort2(t *testing.T) {
	values := []int{5, 5, 4, 3, 2}

	QuickSort(values)

	if values[0] != 2 || values[1] != 3 || values[2] != 4 || values[3] != 5 ||
	values[4] != 5 {
		t.Error("QuickSort failed. Got", values, "Expect 2 3 4 5 5")
	}
}

func TestQuickSort3(t *testing.T) {
	values := []int{5}

	QuickSort(values)

	if values[0] != 5 {
		t.Error("QuickSort failed. Got", values, "Expect 5")
	}
}

