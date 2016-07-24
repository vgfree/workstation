#!/usr/bin/env python3
# -*- coding:utf-8 -*-

class Student(object):
    def __init__(self, name):
        self.name = name
    grade = 'A'

# 根据类创建的实例可以任意绑定属性
s = Student('Bob')
s.score = 90

print(s.name)
print(s.score)


# 实例属性会覆盖类属性
print(Student.grade)
s.grade = 'B'
print(s.grade)


























