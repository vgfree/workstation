
### 7.1 迭代器与closure
1. **迭代器**
  一种可以遍历(iterate over)一种集合中所有元素的机制.通常将迭代器表示为函数,每	
  调用一次函数,即返回集合中的下一个元素.	
2.
每个迭代器都需要在每次成功调用之间保持一些状态,这样才能知道它所在的位置及如何步		
进到下一个位置.		
对于closure 而言,所调用的外部嵌套环境中的局部变量可用于在调用成功之间保持状态值,	
从而使closure可以记住它在一次遍历中所在的位置.	
一个closure结构通常涉及两个函数:closure本身和一个用于创建该closure的factory函数.	
```lua
function values (t)		-- factoryi,每次调用factory时,创建一个新的closure
				-- 这个closure将它的状态保存在其外部变量t和i中
	local i = 0
	return function () i = i + 1
		return t[i]
		end
end
```

### 7.2 泛型for的语义
1. **定义**
```lua
for <var-list> in <exp-list> do
	<body>
end
```
<var-list> 变量列表	
<exp-list> 表达式列表
泛型for在循环过程内部保存了迭代函数.实际上它保存了3个值:	
* 一个迭代函数
* 一个恒定状态	
* 一个控制变量

`for k, v in pairs(t) do print(k, v) end`	
控制变量:变量列表第一个元素 k	
for 对 in 后面的表达式求值,表达式返回三个值(多丢弃,少补nil)给for保存:迭代器函	
\恒定状态\控制变量初值



### 7.3 无状态的迭代器
1. 自身不保存任何状态的迭代器,可以在多个循环中使用同一个无状态迭代器,避免创建新		
 的closure开销
1. ipairs pairs 的对比
2. 后面那个遍历链表的例子没看懂

### 7.4 具有复杂状态的迭代器	
1.将迭代器所需的所有状态打包为一个table,保存在恒定状态中.一个迭代器通过这个	
table就可以保存任意多的数据了.	

