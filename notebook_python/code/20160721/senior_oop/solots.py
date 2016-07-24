#!/usr/bin/env python3
# -*- coding:utf-8 -*-

class Student(object):
    pass

# 绑定属性
s = Student()
s.name = 'louis'
print(s.name)

# 绑定方法, 仅绑定实例可用
def set_age(self, age):
    self.age = age

from types import MethodType

s.set_age = MethodType(set_age, s)
s.set_age(25)

print(s.age)

# 给class绑定方法, 所有实例都可以用
def set_score(self, score):
    self.score = score

Student.set_score = set_score

s.set_score(100)

print(s.score)


# 限制实例的属性
class Country(object):
    __solts__ = ('name', 'capital')

c = Country()
c.name = 'china'
c.capital = 'peiking'
c.population = '1.3b' # 报错, 只能绑定指定的属性

print(c.name)
print(c.capital)

# 继承的子类不受限制
class asiaCountry(Country):
    pass

a = asiaCountry()
a.population = '1.3b'

print(a.population)










































