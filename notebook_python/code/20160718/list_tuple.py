#! /usr/bin/env python3
# -*- coding:utf-8 -*-

classmates = ['louis', 'miku', 'shana']
print(len(classmates))
print(classmates[0])
print(classmates[1])
print(classmates[2])
print(classmates[-1])

classmates.append('asuka')
print(classmates)

classmates.insert(0, 'china')
print(classmates)

classmates.pop()
print(classmates)

classmates.pop(0)
print(classmates)

# 替换指定元素
classmates[0] = 'usa'
print(classmates)

s = ['python', 'java', [271828, True, False], 'c']
print(len(s))
print(s[0])
print(s[2][0])
print(s[2][1])
print(s[2][2])

print('************** tuple *****************')
nations = ('russia', 'usa', 'china', 'korea')
print(nations)

empty = ()
print(empty)

simple = (1,)
print(simple)

tuple = ('a', 'b', ['A', 'B'])
tuple[2][0] = 'X'
tuple[2][1] = 'Y'
print(tuple)

L = [
         ['apple', 'google', 'microsoft'],
         ['java', 'python', 'ruby', 'php'],
         ['louis', 'miku', 'shana']
        ]

print(L[0][0])
print(L[1][1])
print(L[2][2])
