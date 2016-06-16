#!/bin/bash

x=`expr 1 \| 0`
echo $x

y=`expr 0 \& 1`
echo $y

z=$(expr 0 \< 2)
echo $z

i=$(expr 1 != 1)
echo $i

j=`expr 1 + 1`
echo $j

k=`expr 1 \* 1`
echo $k

l=`expr 1 \/ 1`
echo $l

m=`expr 1 % 1`
echo $m

o=`expr length abcdefg`
echo $o

p=`expr $o + 1`
echo $p

q=1.1
r=`expr $q + 1`
echo $r

# 浮点数会报错
# 操作符两边有空格, 部分有转义字符
