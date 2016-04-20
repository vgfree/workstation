local head = supex.get_our_head()

        local header_tab = loadstring("return "..head);
        head = header_tab();

        only.log('D', 'head = %s, %s', type(head), head)

        function string:split(sep)
        local sep, fields = sep or "\t", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
        end

        local result = string.split(head, '\r\n')
        only.log('D', '***********result = %s', scan.dump(result))

        local Accept-Encoding = string.split(result[12], ':')
        only.log('D', Accept-Encoding[2])


        local appKey    = head['appKey']
        local sign      = head['sign']



curl -v -F "filename=@/home/louis/Pictures/test.jpg" -F "length=115339" -F "isStorage=true" -F "cacheTime=200" -H "appKey:1858017065" -H "sign:1545678adsfaf234234234wf" http://192.168.71.84:2223/dfsapi/v2/saveImage




curl -v -F "filename=@/home/louis/Pictures/test.jpg" -F "length=115339" -F "isStorage=true" -F "cacheTime=200" -H "appKey:1858017065" -H "sign:1545678adsfaf234234234wf" http://192.168.71.84:2223/dfsapi/v2/saveImage
