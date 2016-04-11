-- xpcall接收第二个参数——一个错误处理函数，当错误发生时，Lua会在调用桟展看（unwind）前调用错误处理函数，于是就可以在这个函数中使用debug库来获取关于错误的额外信息了

function myfunction ()
        n = n/nil
end

function myerrorhandler( err  )
        print( "ERROR:", err  )
end

status = xpcall( myfunction, myerrorhandler  )
print( status )
