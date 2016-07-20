#!/usr/bin/env python3
# -*- coding:utf-8 -*-

def is_odd(n):
    return n % 2 == 1

# 根据返回值True/False决定保留还是丢弃元素
print(list(filter(is_odd, [1, 2, 3, 4, 5])))


def not_empty(s):
    return s and s.strip()

print(list(filter(not_empty, ['A', '', 'B', 'C', None])))

# 计算素数

# 构造一个从3开始的奇数序列
def _odd_iter():
    n = 1
    while True:
        n += 2
        yield n

# 定义一个筛选函数
def _not_divisible(n):
    return lambda x: x % n > 0

# 定义一个生成器, 不断返回下一个素数
def primes():
    yield 2
    it = _odd_iter()
    while True:
        n = next(it)
        yield n
        it = filter(_not_divisible(n), it) # 构造新序列

for n in primes():
    if n < 1000:
        print(n)
    else:
        break
























