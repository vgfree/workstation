ngx.socket.tcp

syntax: tcpsock = ngx.socket.tcp()

context: rewrite_by_lua*, access_by_lua*, content_by_lua*, ngx.timer.*

Creates and returns a TCP or stream-oriented unix domain socket object (also known as one type of the "cosocket" objects). The following methods are supported on this object:

    * connect
    * send
    * receive
    * close
    * settimeout
    * setoption
    * receiveuntil
    * setkeepalive
    * getreusedtimes 


tcpsock:connect
syntax: ok, err = tcpsock:connect(host, port, options_table?)
syntax: ok, err = tcpsock:connect("unix:/path/to/unix-domain.socket", options_table?) 

tcpsock:send
syntax: bytes, err = tcpsock:send(data) 

tcpsock:receive
syntax: data, err, partial = tcpsock:receive(size)
syntax: data, err, partial = tcpsock:receive(pattern?) 

tcpsock:close
syntax: ok, err = tcpsock:close() 

tcpsock:settimeout
syntax: tcpsock:settimeout(time) 

tcpsock:setoption
syntax: tcpsock:setoption(option, value?) 

tcpsock:setkeepalive
syntax: ok, err = tcpsock:setkeepalive(timeout?, size?) 

ngx.socket.connect
syntax: tcpsock, err = ngx.socket.connect(host, port)
syntax: tcpsock, err = ngx.socket.connect("unix:/path/to/unix-domain.socket") 



--connecting to a TCP server:

location /test {
        resolver 8.8.8.8; # use Google's public DNS nameserver
 
        content_by_lua '
            local sock = ngx.socket.tcp()
            local ok, err = sock:connect("www.google.com", 80)
            if not ok then
                ngx.say("failed to connect to google: ", err)
                return
            end
            ngx.say("successfully connected to google!")
            sock:close()
        ';
    }

--Connecting to a Unix Domain

    local sock = ngx.socket.tcp()
    local ok, err = sock:connect("unix:/tmp/memcached.sock")
    if not ok then
        ngx.say("failed to connect to the memcached unix domain socket: ", err)
        return
    end


--Timeout for the connecting operation is controlled by the "lua_socket_connect_timeout" config directive and the "tcpsock:settimeout" method.

    local sock = ngx.socket.tcp()
    sock:settimeout(1000)  -- one second timeout
    local ok, err = sock:connect(host, port)


--Timeout for the sending operation is controlled by the "lua_socket_connect_timeout" config directive and the "tcpsock:settimeout" method.

    sock:settimeout(1000)  -- one second timeout
    local bytes, err = sock:send(request)

--Timeout for the reading operation is controlled by the "lua_socket_connect_timeout" config directive and the "tcpsock:settimeout" method.

    sock:settimeout(1000)  -- one second timeout
    local line, err, partial = sock:receive()
    if not line then
        ngx.say("failed to read a line: ", err)
        return
    end
    ngx.say("successfully read a line: ", line)

--This method returns an iterator Lua function that can be called to read the data stream until it sees the specified pattern or an error occurs.
--Here is an example for using this method to read a data stream with the boundary sequence --abcedhb:
--When called without any argument, the iterator function returns the received data right before the specified pattern string in the incoming data stream. So, if the incoming data stream is 'hello, world! -agentzh\r\n--abcedhb blah blah', then the string 'hello, world! -agentzh' will be returned.
--[
    local reader = sock:receiveuntil("\r\n--abcedhb")
    local data, err, partial = reader()
    if not data then
        ngx.say("failed to read the data stream: ", err)
    end
    ngx.say("read the data stream: ", data)
--]
    local reader = sock:receiveuntil("\r\n--abcedhb")
 
    while true do
        local data, err, partial = reader(4)
        if not data then
            if err then
                ngx.say("failed to read the data stream: ", err)
                break
            end
 
            ngx.say("read done")
            break
        end
        ngx.say("read chunk: [", data, "]")
    end

Then for the incoming data stream 'hello, world! -agentzh\r\n--abcedhb blah blah', we shall get the following output from the sample code above:

    read chunk: [hell]
    read chunk: [o, w]
    read chunk: [orld]
    read chunk: [! -a]
    read chunk: [gent]
    read chunk: [zh]
    read done



--ngx.socket.connect  is a shortcut for combining ngx.socket.tcp() and the tcpsock:connect() method call in a single operation. 

    local sock = ngx.socket.tcp()
    local ok, err = sock:connect(...)
    if not ok then
        return nil, err
    end
    return sock







    -- query mysql, memcached, and a remote http service at the same time,
    -- output the results in the order that they
    -- actually return the results.
 
    local mysql = require "resty.mysql"
    local memcached = require "resty.memcached"
 
    local function query_mysql()
        local db = mysql:new()
        db:connect{
                    host = "127.0.0.1",
                    port = 3306,
                    database = "test",
                    user = "monty",
                    password = "mypass"
                  }
        local res, err, errno, sqlstate =
                db:query("select * from cats order by id asc")
        db:set_keepalive(0, 100)
        ngx.say("mysql done: ", cjson.encode(res))
    end
 
    local function query_memcached()
        local memc = memcached:new()
        memc:connect("127.0.0.1", 11211)
        local res, err = memc:get("some_key")
        ngx.say("memcached done: ", res)
    end
 
    local function query_http()
        local res = ngx.location.capture("/my-http-proxy")
        ngx.say("http done: ", res.body)
    end
 
    ngx.thread.spawn(query_mysql)      -- create thread 1
    ngx.thread.spawn(query_memcached)  -- create thread 2
    ngx.thread.spawn(query_http)       -- create thread 3

