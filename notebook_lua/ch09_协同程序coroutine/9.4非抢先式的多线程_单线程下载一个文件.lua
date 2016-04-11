
local socket = require 'socket'

host = 'www.w3.org'
file = '/TR/REC-html32.html'
-----------------------------------------------------------
-- 单线程,单个文件
c = assert(socket.connect(host, 80))
local count = 0
c:send('GET ' .. file .. ' HTTP/1.0\r\n\r\n')
while true do
	print(count)
	local s, status, partial = c:receive(2^10)
	count = count + #(s or partial)
	if status == 'close' then break end
end

c:close()

