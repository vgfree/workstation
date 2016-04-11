--[[
if pcall(function_name, ….) then
-- 没有错误
-- else
-- 一些错误
-- end
-- ]]
-- call接收一个函数和要传递个后者的参数，并执行，执行结果：有错误、无错误；返回值true或者或false, errorinfo

pcall(function(i) print(i) end, 33)

pcall(function(i) print(i) error('error..') end, 33)

function f() 
        return false,2 
end

if f() then 
        print '1' 
else 
        print '0' 
end
