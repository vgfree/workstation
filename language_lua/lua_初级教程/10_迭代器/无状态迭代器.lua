-- 每一次迭代，迭代函数都是用两个变量（状态常量和控制变量）的值作为参数被调用，
-- 一个无状态的迭代器只利用这两个值可以获取下一个元素
-- 当Lua调用ipairs(a)开始循环时，他获取三个值：迭代函数iter、状态常量a、控制变量初始值0；
-- 然后Lua调用iter(a,0)返回1,a[1]（除非a[1]=nil）；第二次迭代调用iter(a,1)返回2,a[2]直到第一个nil元素。
function iter (a, i)
        i = i + 1
        local v = a[i]
        if v then
                return i, v
        end
end

function ipairs (a)
        return iter, a, 0
end
