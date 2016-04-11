
mytable = setmetatable({key1 = "value1"}, { 
        __index = { key2 = "metatablevalue"  }  
})
print(mytable.key1, mytable.key2)
