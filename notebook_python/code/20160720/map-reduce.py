#!/usr/bin/env python3
# -*- coding:utf-8 -*-

from functools import reduce

# map 将传入函数依次作用到序列的每个元素, 并将结果作为新的iterator返回

def f(x):
    return x * x

print(list(map(f, [1, 2, 3, 4, 5])))


print(list(map(str, [1, 2, 3, 4, 5])))


# reduce 将结果继续和下一个元素做累计计算

def add(x, y):
    return x + y

print(reduce(add, [1, 2, 3, 4, 5]))

def fn(x, y):
    return x * 10 + y

print(reduce(fn, [1, 3, 5, 7, 9]))
