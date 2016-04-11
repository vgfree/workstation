local cfg = {

        --ip = '192.168.1.3',

        -- ip = '113.207.96.33',

        -- ip = '221.228.229.250',
        
        -- ip = '221.228.231.82',

         ip = '127.0.0.1',

        port = 8088,

        -- path = '/v2/sendTTSPersonalWeibo',

        -- body = '{"appKey":"2064302565", "receiverAccountID":"lAmQoflGq1", "interval":123, "allowYes":1, "text":"hello world", "positionID":"1232", "geometryType":4}'


        --path = '/weiboapi/v2/sendMultimediaPersonalWeibo',

        --body = '{"appKey":"2064302565", "receiverAccountID":"lAmQoflGq1", "interval":123, "multimediaURL":"http://192.168.1.3:80/helo", "positionID":"1232", "geometryType":4, "commentID":"fucking weibo","receiverLongitude":123.45,"receiverLatitude":32.34,"senderLongitude":22.14,"senderLatitude":52.4, "starTime":1400298140}'
       path = '/weiboapi/v2/sendPersonalWeibo',
	--发个人微博    
       body='{"appKey":"4058657628","sourceID":"1340e33c910611e4b76f00a0d1e9d648","sourceType":1,"multimediaURL":"http://127.0.0.1/productList/POIRemind/112311060.amr","messageType":1,"senderLongitude":116.9065760,"senderLatitude":34.7141662,"senderDirection":96,"senderSpeed":69,"senderAltitude":40,"senderType":2,"commentID":"15cfb65ae03a11e39a0600266cf08874","receiverAccountID":"rY9mPvpdlG","receiverLongitude":116.9291964,"receiverLatitude":34.7142600,"receiverDistance":200,"receiverDirection":[94,45],"receiverSpeed":[100,200],"content":"我要回家,我要妈妈","interval":10,"level": 1,"callbackURL":"http://api.daoke.io:80/customizationapp/v2/callbackFetch4MilesAheadPoi?positionType=1123110&POIDirection=[94,45]&POILatitude=34.71426"}'






 
         -- accountID:56YnRD8n3A
         -- userid:56YnRD8n3A
         -- mirrtalkNumber='13038324881'
}


return cfg
