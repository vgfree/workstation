#!/usr/bin/env python3
# -*- coding:utf-8 -*-

# Student 类
class Student(object):
    # __init__ 方法
    def __init__(self, name, score):
        # name 属性
        self.name = name
        self.score = score
    # print_score 方法
    def print_score(self):
        print('%s: %s' % (self.name, self.score))

    def get_grade(self):
        if self.score >= 90:
            return 'A'
        elif self.score >= 60:
            return 'B'
        else:
            return 'C'

# louis 实例 instance
louis = Student('louis tin', 99)
shana = Student('shana asuka', 90)

louis.print_score()
shana.print_score()

print(louis.get_grade())



# 类class: 创建实例的模版
# 实例instance: 一个个具体的对象, 拥有的数据各自独立, 互不影响
# 方法 : 与实例绑定的函数, 方法可以直接访问实例的数据


























