-- function 以匿名函数的方式通过参数传递

function anonymous(tab, fun)
        for k, v in pairs(tab) do
                print(fun(k, v))
        end
end
tab = { key1 = "val1", key2 = "val2"  }
anonymous(tab, function(key, val)
        return key .. " = " .. val
end)

