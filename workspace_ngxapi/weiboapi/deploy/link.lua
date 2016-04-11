module(..., package.seeall)

OWN_POOL = {
    redis = {
        public = {
            host = 'public.redis.daoke.com', 
            port = 6349,
        },
        private = {
            host = 'private.redis.daoke.com',
            port = 6319,
        },
       weibo = {
            host = 'weibo.redis.daoke.com',
            port = 6329,
        },
	statistic = {
            host = 'statistic.redis.daoke.com',
            port = 6339,
        },
	message_redis0= {
            host = 'weibodata.redis.daoke.com',
            port = 6329,
        },
        message_redis1= {
            host = 'weibodata.redis.daoke.com',
            port = 6329,
        },
        message_redis2= {
            host = 'weibodata.redis.daoke.com',
            port = 6329,
        },
        message_redis3= {
            host = 'weibodata.redis.daoke.com',
            port = 6329,
        },


	mapGridOnePercent = { 
            host = 'map.redis.daoke.com',
            port = 5071,
        },

    },
    mysql = {
        app_weibo___weibo = {
            host = 'db3.mysql.daoke.com',
            port = 3306,
            database = 'app_weibo',
            user = 'app_weibo',
            password ='258MTweibo',
        },
        app_usercenter___usercenter = { 
            host = 'db2.mysql.daoke.com',
            port = 3306,
            database = 'userCenter',
            user = 'app_user',
            password ='DKuser751',
        },
	app_roadmap___roadmap = {
            host = 'roadmap.mysql.daoke.com',
            port = 3306,
            database = 'roadMap',
            user = 'app_roadmap',
            password ='MTrmap369',
        },
    },
}


OWN_DIED = {
    redis = {
    },
    mysql = {
 
    },

    http = {
        dfsapi_txt2voice = {
            host = 'txt2v1.server.daoke.com',
            port = 80,
        },
        dfsapi_save_sound = {
            host = 'api.daoke.io',
            port = 80,
       },
        -- send personal weibo
        weiboapi = {
            host = 'api.daoke.io',
            port = 80,
        },
	-- this is the host and port of callback api
        callbackapi = {
            host = 'api.daoke.io',
            port = 80,
        },


    },
}


setmetatable(_M, { __index = _M })
