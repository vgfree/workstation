local cfg = {

        -- ip = '115.238.169.149',

        -- ip = '221.228.229.250',

        -- ip = '113.207.96.33',
	-- 此处为服务器IP地址
        ip = '192.168.1.207',
        -- ip = '192.168.1.3',

        port = 80,

        -- path = '/v2/sendTTSGroupWeibo',

        -- body = '{"appKey":"2064302565","senderAccountID":"lAmQoflGq1", "groupID":"mirrtalkAll", "interval":25000, "text":"插播新闻:2月26日24时,国内汽柴油零售价格每升分别提高0.15元和0.17元.请您适时为爱车加油."}'


        path = '/weiboapi/v2/sendMultimediaGroupWeibo',

        body = '{"appKey":"2064302565","senderAccountID":"lAmQoflGq1", "groupID":"111111111", "interval":600, "multimediaURL":"http://v1.mmfile.daoke.me/dfsapi/v2/gainSound?isStorage=true%26group=dfsdb_8%26file=1457401032%3A480ca2aae4ce11e58faa984be10d2298.amr","level":20,"receiveSelf":0,"skipChannelAuthorize":1}'



         -- accountID:56YnRD8n3A
         -- userid:56YnRD8n3A
         -- mirrtalkNumber='13038324881'
}


return cfg
