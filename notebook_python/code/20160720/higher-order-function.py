#!/usr/bin/env python3

# 一个函数可以接受另一个函数作为参数

def add(x, y, f):
    return f(x) + f(y)


print(add(-5, 6, abs))
