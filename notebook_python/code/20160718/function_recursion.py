#!/usr/bin/env python3
# -*- coding:utf-8 -*-

def fact(n):
    return fact_iter(n, 1)

def fact_iter(num, product):
    if num == 1:
        return product
    return fact_iter(num - 1, num * product)

print(fact(5))

i = 0

def move(n, From, To):
        print('将 %d 号盘子 %s --> %s ' % (n, From, To))

def hanoi(n, a, b, c):
    if n == 1:
        move(1, a, c)
    else:
        hanoi(n - 1, a, c, b)
        move(n, a, c)
        hanoi(n - 1, b, a, c)

print(hanoi(8, 'a', 'b', 'c'))
