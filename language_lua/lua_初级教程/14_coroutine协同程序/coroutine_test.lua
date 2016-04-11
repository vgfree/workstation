co = coroutine.create(
function(i)
        print(i);
end

)

coroutine.resume(co, 1)   -- 1 传参1
print(coroutine.status(co))  -- dead 调用后函数已经执行完毕,所以为dead

print("----------")

co = coroutine.wrap(
function(i)
        print(i);
end

)

co(1)

print("----------")

co2 = coroutine.create(
function()
        for i=1, 10 do
                print(i)
                if i == 3 then
                        print(coroutine.status(co2))  --running
                        print(coroutine.running()) --thread:XXXXXX
                end
                coroutine.yield()
        end
end

)

coroutine.resume(co2) --1 每调用一次就执行一次，因为循环还没执行完毕，每次都会yield,所以会suspend
coroutine.resume(co2) --2
coroutine.resume(co2) --3

print(coroutine.status(co2))   -- suspended
print(coroutine.running())

print("----------")
