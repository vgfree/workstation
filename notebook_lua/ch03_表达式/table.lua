polyline =	{color = 'blue', number = 4,
{x = 0, y = 0},
{x = 10, y = 10},
{x = 20, y = 20}
}

print(polyline['color'])
print(polyline[3]['x'])
print(polyline[3].y)

-- 很神奇的是最后两个输出都是20，这说明了table的key开始时是'color'，'number'，后面是'1','2','3'
print('-------------------------------\n')
opnames = {['+'] = 'add', ['-'] = 'sub', ['*'] = 'mul', ['/'] = 'div'}

i = 20
s = '-'
a = {[i+0] = s, [i+1] = s .. s, [i+2] = s .. s .. s}

print(opnames[s])
print(a[20])
print(a[22])

print('-------------------------------\n')
num = {x = 10, y = 20; 'one', 'two', 'three'}
print(num['x'])
print(num[3])

-- 此处第二个输出three, 印证了上面的猜想，而且中间用分号作分隔更明显
