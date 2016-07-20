#!/usr/bin/env python3

L = []
for x in range(1, 11):
    L.append(x * x)

print(L)

print([x * x for x in range(1, 11)])

print([x * x for x in range(1, 11) if x % 2 == 0])

print([m + n for m in 'ABC' for n in 'XYZ'])



import os

print([d for d in os.listdir('.')])

d = {'x':'A', 'y':'B', 'z':'C'}
print([k + '=' + v for k, v in d.items()])

L1 = ['Hello', 'World', 'IBM', 'Apple']
print([s.lower() for s in L1])

x = 'abc'
y = 123

print(isinstance(x, str))
#print(isinstance(y, str))




L2 = ['Hello', 'World', 'IBM', 'Apple', 18, None]
L3 = []

print([s.upper() if isinstance(s, str) == True else s for s in L2])

for index, s1 in enumerate(L2):
    if isinstance(s1, str) == True:
        L3.append(s1.upper())
    else:
        L3.append(s1)

print(L3)






