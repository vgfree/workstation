#!/usr/bin/env python3
# -*- coding:utf-8 -*-

d = {'china':960, 'usa':930, 'russia':1710, 'japan':37}
print(d['japan'])

d['japan'] = 36
print(d['japan'])

print('japan' in d)

print(d.pop('japan'))

print(d.get('japan', -1))

d['turkey'] = 72

print(d)

print('***************** set 只有key,不存value *****************')

s = set([2, 2, 3, 3, 4, 4])
print(s)

s.add(5)
print(s)

s.remove(3)
print(s)

s2 = set([1, 2, 3])
print(s2)

print(s & s2)
print(s | s2)


print('************** 不可变对象 **************')

a = ['b', 'a', 'c']
a.sort()
print(a)

print('************** 可变对象 **************')
str1 = 'abc'

str2 = str1.replace('a', 'A')
print(str1)
print(str2)






