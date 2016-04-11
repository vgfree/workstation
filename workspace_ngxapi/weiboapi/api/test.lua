local zmq_api = require("zmq_api")

local data = {
	"aaaaaa",
	"bbbbbb"
}

local ok = zmq_api.cmd("test", "send_table", data)

local ok, data = zmq_api.cmd("test", "recv_table")
for i=1,#data do
	ngx.say(data[i])
end

