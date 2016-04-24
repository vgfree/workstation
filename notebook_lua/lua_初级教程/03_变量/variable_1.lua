local a = 5     -- 全局变量
local b = 5     -- 局部变量

function joke()
        c = 5           -- 局部变量
        local d = 6 -- 局部变量
end

print(c,d)      --> nil nil

do
        local a = 6 -- 局部变量
        b = 6           -- 全局变量
        print(a,b); --> 6 6
end

print(a,b)      --> 5 6

