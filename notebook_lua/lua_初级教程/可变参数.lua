function fun(...)
--        for i, v in ipairs(arg) do
--                print(v)
--        end

        return arg
        --print("测试")
end

argc = {}

argc = fun(1, 2, 3, 4)

function fun1(argc)
        for i, v in ipairs(argc) do
                print(v)
        end
end

fun1(argc)

