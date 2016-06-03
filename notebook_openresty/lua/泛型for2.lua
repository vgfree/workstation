local days = {
	"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday","Sunday"
}

local revDays = {}
for i, v in ipairs(days) do
	revDays[v] = i
end

for k,v in pairs(revDays) do
	print("k:", k, "\tv:", v)
end
