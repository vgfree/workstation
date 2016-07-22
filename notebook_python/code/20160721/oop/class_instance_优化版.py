#!/usr/bin/env python3
# -*- coding:utf-8 -*-

# Student 类
class Student(object):
    # __init__ 方法
    def __init__(self, name, score):
        # name 属性
        # -- 前缀 private属性
        self.__name = name
        self.__score = score
    # print_score 方法
    def print_score(self):
        print('%s: %s' % (self.__name, self.__score))
    # 供外部调用private 变量
    def get_name(self):
        return self.__name

    def get_score(self):
        return self.__score

    # 供外部修改private变量
    def set_name(self, name):
        self.__name = name
    # 可以做参数检查
    def set_score(self, score):
        if 0 <= score <= 100:
            self.__score = score
        else:
            raise ValueError('bad score')

    def get_grade(self):
        if self.__score >= 90:
            return 'A'
        elif self.__score >= 60:
            return 'B'
        else:
            return 'C'

# louis 实例 instance
louis = Student('louis tin', 99)
shana = Student('shana asuka', 90)

louis.print_score()
shana.print_score()

print(louis.get_grade())
print(louis.get_name())

louis.set_score(100)
print(louis.get_score())


# 类class: 创建实例的模版
# 实例instance: 一个个具体的对象, 拥有的数据各自独立, 互不影响
# 方法 : 与实例绑定的函数, 方法可以直接访问实例的数据
# _ 单下划线变量: 外部可以访问, 但是尽量不要

























