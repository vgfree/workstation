
### 6.1 闭合函数 closure

### 6.2 非全局函数 non-global function

1. 局部函数语法定义
```lua
local function foo(x)
	<body>
end
```
展开为
```lua
local foo
foo = function (x)
	<body>	
	end

```
### 6.3 尾调用 proper tail call
1. 一个函数调用是另一个函数的最后一个动作时
```lua
return <func>(<args>)
```
错误形式:	
```lua
function f (x) g (x) end	-- 没有return, 最后一个动作是丢弃返回值
return g(x) + 1			-- 最后一个动作是加法
return x or g(x)		-- 必须调整为一个返回值
return (g(x))			-- 必须调整为一个返回值
```


