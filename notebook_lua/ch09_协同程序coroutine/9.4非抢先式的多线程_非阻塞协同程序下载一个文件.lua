
local socket = require 'socket'

host = 'www.w3.org'
file = 'TR/REC-html32.html'

function receive(connection)
	connection:settimeout(0)
	local s, status, partial = connection:receive(2^10)
	if status == 'timeout' then
		coroutine.yield(connection)
	end
	return s or partial, status 
end
function download (host, file)
	local c = assert(socket.connect(host, 80))
	local count = 0		-- 记录接收的字数
	c:send('GET ' .. file .. ' HTTP/1.0\r\n\r\n')

	while true do
		print(count)
		local s, status, partial = receive(c)
		count = count + #(s or partial)
		if status == 'closed' then break end
	end
	c:close()
	print(file, count)
end

download(host, file)

--]]
-----------------------------------------------------------
