-- ... 表示函数有可变参数
-- 可变参数放在一个叫 arg 的表中， #arg表示传如的个数
function average(...)
        result = 0
        local arg={...}
        for i,v in ipairs(arg) do
                result = result + v
        end
        print("总共传入 " .. #arg .. " 个数")
        return result/#arg
end

print("平均值为",average(10,5,3,4,5,6))
