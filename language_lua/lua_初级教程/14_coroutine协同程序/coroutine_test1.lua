function foo (a)
        print("foo 函数输出", a)
        return coroutine.yield(2 * a) -- 返回  2*a 的值
end

co = coroutine.create(function (a , b)
        print("第一次协同程序执行输出", a, b) -- co-body 1 10
        local r = foo(a + 1)

        print("第二次协同程序执行输出", r)
        local r, s = coroutine.yield(a + b, a - b)  -- a，b的值为第一次调用协同程序时传入

        print("第三次协同程序执行输出", r, s)
        return b, "结束协同程序"                   -- b的值为第二次调用协同程序时传入
end)

-- 调用顺序
-- 1. co 先执行， 输出"第一次... 1 10"
-- 2. 再执行 foo, 输出"foo 函数输出 2", 并向resume返回 4 
-- 3. print 打印 "main ture 4", true 是resume 唤醒调用成功
print("main", coroutine.resume(co, 1, 10)) -- true, 4
print("--分割线----")
print("main", coroutine.resume(co, "r")) -- true 11 -9
print("---分割线---")
print("main", coroutine.resume(co, "x", "y")) -- true 10 end
print("---分割线---")
print("main", coroutine.resume(co, "x", "y")) -- cannot resume dead coroutine
print("---分割线---")
