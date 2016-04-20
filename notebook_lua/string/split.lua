
function string:split(sep)  
	local sep, fields = sep or "\t", {}  
	local pattern = string.format("([^%s]+)", sep)  
	self:gsub(pattern, function(c) fields[#fields+1] = c end)  
	return fields  
end  

local string = ""
local result = string.split(string, ",")
