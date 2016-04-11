-- 计算表中最大值，table.maxn在Lua5.2以上版本中已无法使用
-- 自定义计算表中最大值函数 table_maxn
function table_maxn(t)
        local mn = 0
        for k, v in pairs(t) do
                if mn < k then
                        mn = k
                end
        end
        return mn
end

-- 两表相加操作
mytable = setmetatable({ 1, 2, 3 }, {
        __add = function(mytable, newtable)
                for i = 1, table_maxn(newtable) do
                        table.insert(mytable, table_maxn(mytable)+1,newtable[i])
                end
                return mytable
        end
})

secondtable = {4,5,6}

mytable = mytable + secondtable
for k,v in ipairs(mytable) do
        print(k,v)
end

-- table_maxn 能获取table 中最大值，在这里就是3，然后+1 就是4， 即在table([4])
-- 位置插入secondtable 的第一个元素 4,后面的以此类推
