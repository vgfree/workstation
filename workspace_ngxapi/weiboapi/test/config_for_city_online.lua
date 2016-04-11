local cfg = {

        -- ip = '115.238.169.149',

        -- ip = '221.228.229.250',

        -- ip = '113.207.96.33',

        -- ip = '192.168.1.3',
        
        ip = '127.0.0.1',

        port = 8088,

        -- path = '/v2/sendTTSOnlineCityWeibo',

        -- body = '{"appKey":2064302565, "senderAccountID":"lAmQoflGq1", "regionCode":310105, "interval":25000, "text":"插播新闻:2月26日24时,国内汽柴油零售价格每升分别提高0.15元和0.17元.请您适时为爱车加油."}'


        path = '/v2/sendMultimediaOnlineCityWeibo',

        body = '{"appKey":2064302565, "senderAccountID":"lAmQoflGq1", "regionCode":310105, "interval":25000, "multimediaURL":"http://baiudu.com/gufang"}'


         -- accountID:56YnRD8n3A
         -- userid:56YnRD8n3A
         -- mirrtalkNumber='13038324881'
}


return cfg
