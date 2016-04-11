days = {"Sun", "Mon", "Tus", "Wed", "Thu", "Fri", "Sat"}
local revdays = {}
for k, v in ipairs(days) do
	revdays[v] = k
	print(revdays[v])
end
