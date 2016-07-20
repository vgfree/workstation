#!/usr/bin/env python3
# -*- coding:utf-8 -*-

a = abs

print(a(-1))

print(max(1, 3, 5, 2, 4))

print(int('1234'))

print(int(12.34))

print(float('12.34'))

print(str(12.34))

print(bool(1))

print(bool(''))

print(str(hex(255)))

print('********** 定义函数 ************')

def my_abs(x):
    if not isinstance(x, (int, float)):
        raise TypeError('bad oprand type')
    if x >= 0:
        return x
    else:
        return -x

print(my_abs(-1))

def nop():
    pass


print('********** 返回多个值 ************')

print(math.cos(1))

def move(x, y, step, angle = 0):
    nx = x + step * math.COS(angle)
    ny = y + step * math.SIN(angle)
    return nx, ny

print(move(100, 100, 60, math.PI / 6))






