#!/usr/bin/env python3
# -*- coding:utf-8 -*-

print('***** 默认参数 *****')

def power(x, n = 2):
    s = 1
    while n > 0:
        s *= x
        n -= 1
    return s

print(power(5))
print(power(5, 3))


def enroll(name, gender, age = 6, city = 'Beijing'):
    print('name:', name)
    print('gender:', gender)
    print('age:', age)
    print('city:', city)
    print('\n')
# 函数无返回值, 会返回None

print(enroll('louis', 'A', 7))
print(enroll('shana', 'B', city = 'Shanghai'))

def add_end(L = None):
    if L is None:
        L = []
        L.append('END')
    return L

print(add_end())

print('***** 可变参数 *****')

def calc(*numbers):
    sum = 0
    for n in numbers:
        sum += n * n
    return sum

print(calc())
print(calc(1, 2, 3))

# 将接收到的list/tuple转化为tuple
nums = [1, 2, 3]
print(calc(*nums))


print('***** 关键字参数 *****')
# 关键字参数名字可以自己定
def person(name, age, **kw):
    if 'city' in kw:
        pass
    if 'job' in kw:
        pass
    print('name:', name, 'age:', age, 'other:', kw)

print(person('louis', 20))

# 将dict先组装为一个dict, 即将拷贝文件传入函数
extra = {'city':'beijing', 'job':'engineer'}
print(person('louis', 20, **extra))

print('***** 命名关键字参数 *****')
# 限制关键字参数名字
def student(name, age, *, school = 'CSU', sex):
    print(name, age, school, sex)


print(student('louis', 20, sex = 'male'))


print('******** 参数组合 *********')

# 必选参数 默认参数 可变参数 命名关键字参数 关键字参数

def f1(a, b, c = 0, *args, **kw):
    print('a = ', a, 'b = ', b, 'c = ', c, 'args = ', args, 'kw = ', kw)

def f2(a, b, c = 0, *, d, **kw):
    print('a = ', a, 'b = ', b, 'c = ', c, 'd = ', d, 'kw = ', kw)

print(f1(1, 2, 3, 'a', 'b', x = 99))

print(f2(1, 2, d = 4, x = 99))

args = (1, 2, 3, 4)
kw = {'d':99, 'x':'#'}

print(f1(*args, **kw))

args = (1, 2, 3)

print(f2(*args, **kw))


print('************** 递归函数 ****************')


