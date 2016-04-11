for i=10,1,-1 do
        print(i)
end

print("*******************")

function f(x)  
        print("function")  
        return x*2   
end  
for i=1,f(5) do print(i)  -- 表达式在循环开始前一次性求值，其结果用在后面的循环中
end  
