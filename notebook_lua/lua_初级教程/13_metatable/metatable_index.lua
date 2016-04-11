-- __index元方法查看表中元素是否存在,存在则由__index 返回结果，不存在返回nil
mytable = setmetatable({key1 = "value1"}, {
        __index = function(mytable, key)
                if key == "key2" then
                        return "metatablevalue"
                else
                        return mytable[key]
                end
        end
})

print(mytable.key1,mytable.key1) -- value1 value1 
print(mytable.key1,mytable.key2) -- value1 metatablevalue

-- 元方法查看是否传入key2 键的参数，如果传入key2 参数，返回 metatablevalue 否则返回mytable 对应的键值 
