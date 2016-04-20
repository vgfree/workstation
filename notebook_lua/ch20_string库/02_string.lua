--[[
string.find
string.gsub
string.gfind
--]]

s = "hello world"
i, j = string.find(s, "hello")
print(i, j)

print(string.sub(s, i, j))

print(string.find(s, "world"))

i, j = string.find(s, "l")
print(i, j)

print(string.find(s, "lll"))
