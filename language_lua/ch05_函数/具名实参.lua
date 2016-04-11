function rename_file(arg)
	if type(arg.old) ~= "string" then
		error("no old name!")
	elseif type(arg.new) ~= "string" then 
		error("no new name!")
	end

	return os.rename(arg.old, arg.new)
end

rename_file{old = "old.txt", new = "new.txt"}

-- 依然是一个大写的不明白，留到以后再看吧
