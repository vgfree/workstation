#!/usr/bin/env python3
# -*- coding:utf-8 -*-

print('my', 'name', 'is', 'louis')

print('100 + 200 = ', 100 + 200)

print('I\'m \"OK\"!')

print('\\\t\\')

print(r'\\\t\\')

print('''line1
line2
line3''')

print('\'A\'的unicode编码为', ord('A'))

print('65转换为unicode编码为', chr(65))

print('\u4e2d字符十六进制编码转换:', str('\u4e2d'))

print('ABC'.encode('ascii'))
print(b'ABC'.decode('ascii'))

print('中文'.encode('utf-8'))
print(b'\xe4\xb8\xad\xe6\x96\x87'.decode('utf-8'))

print(len('ABC'))
print(len(b'ABC'))
print(len('中文'.encode('utf-8')))

s1 = 72
s2 = 85

print('date : %4d-%02d-%02d' % (2016, 7, 18))
print('growth rate : %.1f %%' % ((s2 - s1) / s1 * 100))





