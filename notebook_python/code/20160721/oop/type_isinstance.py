#!/usr/bin/env python3
# -*- coding:utf-8 -*-

print(type(123))
print(type('ab'))

class Animal(object):
    def __len__(self):
        return 100
    def __init__(self):
        self.x = 9
    def power(self):
        pass

a = Animal()

print(isinstance(a, Animal))

# 在a内部有许多方法
print(dir(a))


print(len('ABC'))
print('ABC'.__len__())
print(len(a))

# 对象中是否有属性x
print(hasattr(a, 'x'))
print(hasattr(a, 'y'))
# 设置对象属性
print(setattr(a, 'y', 10))
print(hasattr(a, 'y'))
# 获取对象属性
print(getattr(a, 'y'))
print(a.y)

print(getattr(a, 'z', 404))
print(hasattr(a, 'power'))











