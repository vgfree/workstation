#!/usr/bin/env python3

def fib(max):
    n, a, b = 0, 0, 1
    while n < max:
        yield b
        a, b = b, a + b
        n += 1
    return 'done'

o = fib(6)
print(next(o))
print(next(o))
print(next(o))
print(next(o))

print('\n')

for n in fib(6):
    print(n)

print('\n')

g = fib(6)

while True:
    try:
        x = next(g)
        print(x)
    except StopIteration as e:
        print('Generator return value:', e.value)
        break





def triangle(max):
    N = [1]
    n = 0
    while n < max:
        yield N
        N.append(0)
        N = [N[i - 1] + N[i] for i in range(len(N))]
        n += 1

for t in triangle(10):
    print(t)











