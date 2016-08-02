构建与执行
```
[louis@louis src]$  go build sorter/algorithms/qsort 
[louis@louis src]$  go build sorter/algorithms/bubblesort
[louis@louis src]$  go test sorter/algorithms/bubblesort
ok		sorter/algorithms/bubblesort	0.003s
[louis@louis src]$  go test sorter/algorithms/qsort
ok		sorter/algorithms/qsort	0.004s
[louis@louis src]$  go install sorter/algorithms/qsort
[louis@louis src]$  go install sorter/algorithms/bubblesort
[louis@louis src]$  go build sorter
go install sorter: build output "sorter" already exists and is a directory
[louis@louis src]$  go install sorter
```
