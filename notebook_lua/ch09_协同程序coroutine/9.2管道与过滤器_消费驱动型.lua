print('-----------生产者与消费者-------------')
print('-----------消费者驱动型-------------')
do
	function receive ()
		local status, value = coroutine.resume(producer)	-- 对resume的调用不会启动一个新函数,而是从一次yield调用中返回
		return value
	end

	function send (x)
		coroutine.yield(x)	-- 当一个协同程序调用yield时,它不是进入了一个新的函数,而是从一个悬而未决的resume调用中返回
	end

	producer = coroutine.create(
	function ()
		while true do
			local x = io.read()
			send(x)
		end
	end)

	function consumer ()
		while true do
			local x = receive()
			io.write(x, '\n')
		end
	end

	consumer()
	
	--consumer --> receive -resume-> producer --> io.read --> send x -yield-> recieve --> io.write 
	
end
