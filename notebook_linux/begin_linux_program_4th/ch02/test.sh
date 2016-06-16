#!/bin/bash

echo The current directory is $PWD
echo The current users are $(who)

exit 0

# 将括号互换输出就不一样了
# PWD是shell命令, who是系统命令, 替换为pwd就需要括号了




