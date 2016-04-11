-- __newindex 元方法用来对表更新，__index用来对表访问
-- 当给一个表所缺少的索引赋值，解释器就会查找__newindex 元方法:如果存在则调用这个函数而不进行赋值操作

mymetatable = {}
mytable = setmetatable({key1 = "value1"}, { __newindex = mymetatable  })

print(mytable.key1)

-- 对新索引键newkey赋值时，由于该键不存在所以回调用元方法，而不进行赋值
mytable.newkey = "新值2"
print(mytable.newkey, mymetatable.newkey)

-- 此时key1已经存在就会进行赋值操作,即mytable.key1会更新为“新值1”,而不会调用__newindex元方法
mytable.key1 = "新值1"
print(mytable.key1, mymetatable.key1)

