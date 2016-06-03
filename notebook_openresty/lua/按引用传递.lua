function change(arg)
	arg.width = arg.width * 2
	arg.height = arg.height * 2
end



local rectangle = { width = 20, height = 15  }
print("before change:", "width = ", rectangle.width, " height = ", rectangle.height)
change(rectangle)
print("after change:", "width = ", rectangle.width, " height =", rectangle.height)
