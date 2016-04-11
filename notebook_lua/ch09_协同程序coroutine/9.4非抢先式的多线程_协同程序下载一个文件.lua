
local socket = require 'socket'

host = 'www.w3.org'
file = '/TR/REC-html32.html'
--[[
-----------------------------------------------------------
-- 单线程,单个文件
c = assert(socket.connect(host, 80))
c:send('GET ' .. file .. ' HTTP/1.0\r\n\r\n')
while true do
	print(i)
	local s, status, partial = c:receive(2^10)
	io.write(s or partial)
	if status == 'close' then break end
end

c:close()

--]]
--
-----------------------------------------------------------
-- 以协同程序来实现并发(真没看出来怎么做到的)
function receive(connection)
	return connection:receive(2^10)
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
