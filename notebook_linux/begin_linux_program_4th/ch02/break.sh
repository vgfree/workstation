#!/bin/bash

rm -rf fred*
echo > fred1
echo > fred2
mkdir fred3
mkdir fred4

for file in fred*
do
	if [ -d "$file" ]; then
		break
	fi
done

echo first directory starting fred was $file

rm -rf fred*

exit 0

# 在控制条件满足之后, 跳出循环
