#!/bin/bash

echo the date is $(date)
set $(date)
echo The weekend is $1
echo The month is $2

exit 0

# 为shell 设置参数变量, 可以输出结果中的某个域
