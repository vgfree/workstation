#!/bin/bash

x=0
while [ "$x" -ne 10 ]; do
	echo $x
#	x=$($x+1)
	x=$(($x+1))
done

exit 0

# 第一种情况下, x的值为"0+1"字符串
