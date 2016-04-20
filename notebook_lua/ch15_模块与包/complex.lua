local modname = ...
local M = {}
_G.modname = M
package.loaded[modname] = M

M.i = {r = 0, i = 1}
function M.new(r, i) return {r = r, i = i} end

function M.add(c1, c2)
	return M.new(c1.r + c2.r, c1.i + c2.i)
end

function M.sub(c1, c2)
	return M.new(c1.r - c2.r, c1.i - c2.i)
end

function M.mul(c1, c2)
	return M.new(c1.r * c2.r, c1.i * c2.i)
end

local function inv(c)
	local n = c.r ^ 2 + c.i ^ 2
	return M.new(c.r / n, -c.i / n)
end

local function div(c)
	return M.mul(c1, inv(c2))
end


-- 实在没看明白这是在做什么 20160419
