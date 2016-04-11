-- module 模块为上文提到到 module.lua
-- -- 别名变量 m
-- require 用于搜索 Lua 文件的路径是存放在全局变量 package.path 中
-- 当 Lua 启动后，会以环境变量 LUA_PATH 的值来初始这个环境变量。
-- 如果没有找到该环境变量，则使用一个编译时定义的默认路径来初始化。
local m = require("module")

print(m.constant)

m.func3()

m.func1()
