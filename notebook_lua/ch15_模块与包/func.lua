
module("func", package.seeall)

value = "我是一个共有变量"


function func1()
	return io.write("这是一个公有函数！\n")
end

local function func2()
	return io.write("这是一个私有函数！\n")
end

function func3()
	return func2()
end

