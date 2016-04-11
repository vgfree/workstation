

mytable = setmetatable({key1 = "value1"}, {
        __newindex = function(mytable, key, value)
                rawset(mytable, key, "\""..value.."\"")

        end

})

mytable.key1 = "new value"
mytable.key2 = 4

-- key1已经存在，覆盖为新值；key2不存在，利用rawset更新table得到 “4”
print(mytable.key1, mytable.key2)

