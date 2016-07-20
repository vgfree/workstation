#!/usr/bin/env python
# -*- coding:utf-8 -*-

from functools import reduce

def str2int(s):
    def fn(x, y):
        return 10 * x + y
    def char2num(s):
        return {'0':0, '1':1, '2':2, '3':3, '4':4, '5':5, '6':6, '7':7, '8':8,
                '9':9}[s]
    return reduce(fn, map(char2num, s))

print(str2int('9527'))


print('******** 练习题 *********')

def normalize(name):
    name.lower()
    return name.capitalize()

L1 = ['adam', 'LISA', 'barT']
L2 = list(map(normalize, L1))
print(L2)
