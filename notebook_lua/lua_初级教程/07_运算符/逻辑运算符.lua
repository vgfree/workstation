-- and 逻辑与
-- or 逻辑或
-- not 逻辑非


a = 5
b = 20

if ( a and b  )
        then
                print("Line 1 - 条件为 true" )
        end

if ( a or b  )
        then
                print("Line 2 - 条件为 true" )
        end

-- 修改 a 和 b 的值
a = 0
b = 10

if ( a and b  )
        then
                print("Line 3 - 条件为 true" )
        else
                print("Line 3 - 条件为 false" )
        end

if ( not( a and b )  )
        then
                print("Line 4 - 条件为 true" )
        else
                print("Line 3 - 条件为 false" )
        end
