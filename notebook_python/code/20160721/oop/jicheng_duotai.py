#!/usr/bin/env python3
# -*- coding:utf-8 -*-

# 基类 Base class
class Animal(object):
    def run(self):
        print('Animal is running...')

# 子类 Subclass
class Dog(Animal):
    def run(self):
        print('Dog is running ...')

    def eat(self):
        print('Eating meat ...')

class Cat(Animal):
    pass

# 子类获取父类全部功能
cat = Cat()
cat.run()

# 子类方法覆盖父类方法  多态
dog = Dog()
dog.run()

print(isinstance(cat, Animal))
# 子类可以继承父类的数据类型
print(isinstance(dog, Animal))
print(isinstance(dog, Dog))


# 多态的好处
def run_twice(animal):
    animal.run()
    animal.run()

run_twice(Animal())

run_twice(Dog())

# 新增的子类, 可以直接运行
class Tortoise(Animal):
    def run(self):
        print('Tortoise is running slowly ...')

run_twice(Tortoise())

# 鸭子类型, 看继承并没有那么严格, 只要传入对象有一个run方法就可以了
class Timer(object):
    def run(self):
        print('Start ...')

run_twice(Timer())

# 多态的好处是, 传入Dog Tortoise 时, 只需要接收Animal类型, 然后按照Animal类型进
# 行操作, 只要接收的是Animal类或者其子类, 都会自动调用run方法

# 继承可以把父类的所有功能都直接拿过来用, 这样不必从0开始,
# 子类只需要新增自己特有的方法, 也可以把父类不适合的方法覆盖重写














