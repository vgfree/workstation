for i = 1, ARGV[1] do
	redis.call('sadd', KEYS[1], 1234567890 - i)
end

return 1
