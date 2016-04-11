--[[
--t = {}
s = "from=world, to=Lua"
for k, v in string.gmatch(s, "(%w+)=(%w+)") do
　t[k]=v
end
for k, v in pairs(t) do
　print(k, v)
end
--]]

s = "just a test"
for w in string.gmatch(s, "%a+") do
        print(w)
end


print(string.sub("abcdefg", 1, -1))

print("*****************************************")

local str = "Hello12345World"
local subStr = string.match(str, "%d+")
print(subStr)


local account = '100'
local isum = '111'
local tmp = string.format("%s hello", account, isum)

print(tmp)
