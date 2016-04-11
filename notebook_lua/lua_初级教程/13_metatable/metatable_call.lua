
function table_maxn(t)
        local mn = 0
        for k, v in pairs(t) do
                if mn < k then
                        mn = k
                end
        end
        return mn
end


-- 定义元方法__call
mytable = setmetatable({10}, {
        __call = function(mytable, newtable)
                sum = 0
                -- 此处mytable 只有一个成员10，所以循环结束后sum = 10
                for i = 1, table_maxn(mytable) do
                        sum = sum + mytable[i]
                end
                -- 用10加上newtable的成员, table_maxn得出的是最大成员数
                for i = 1, table_maxn(newtable) do
                        sum = sum + newtable[i]
                end
                return sum
        end

})
newtable = {10,20,30}
print(mytable(newtable))

