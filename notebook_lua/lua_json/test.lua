local cjson = require "cjson"
local sampleJson = [[{"age":"23","testArray":{"array":[8,9,11,14,25]},"Himi":"himigame.com"}]];
--解析json字符串
local data = cjson.decode(sampleJson);
----打印json字符串中的age字段
print(data["age"]);
----打印数组中的第一个值(lua默认是从0开始计数)
print(data["testArray"]["array"][1]);   
