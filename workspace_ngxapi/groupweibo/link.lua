module(..., package.seeall)

OWN_POOL = {
    redis = {
        public = {
            host = '192.168.1.11', 
            port = 6349,
        },
        private = {
            host = '192.168.1.11',
            port = 6319,
        },
        weibo = {
            host = '192.168.1.11',
            port = 6329,
        },
        statistic = {
            host = '192.168.1.11',
            port = 6339,
        },
        ---- 使用1%的网格数据,运维请注意*** 2014-06-18 jiang z.s. 
        mapGridOnePercent = { 
            host = '192.168.71.61',
            port = 5071,
        }, 

        dataCore_redis = {
                host = '192.168.1.13',
                port = 8001,
        },
	message_redis0= {
            host = '192.168.71.45',
            port = 6379,
        },
        message_redis1= {
            host = '192.168.71.45',
            port = 6379,
        },
        message_redis2= {
            host = '192.168.71.45',
            port = 6379,
        },
        message_redis3= {
            host = '192.168.71.45',
            port = 6379,
        },
--[[
	message_redis0= {
            host = '192.168.1.195',
            port = 6379,
        },
        message_redis1= {
            host = '192.168.1.195',
            port = 6379,
        },
        message_redis2= {
            host = '192.168.1.195',
            port = 6379,
        },
        message_redis3= {
            host = '192.168.1.195',
            port = 6379,
        },
]]--

    },
    mysql = {
        app_weibo___weibo = {
            host = '192.168.1.6',
            port = 3306,
            database = 'app_weibo',
            user = 'app_weibo',
            password ='258MTweibo',
        },
        app_usercenter___usercenter = { 
            host = '192.168.1.6',
            port = 3306,
            database = 'userCenter',
            user = 'app_user',
            password ='DKuser751',
        },
        app_roadmap___roadmap = { 
            host = '192.168.1.6',
            port = 3306,
            database = 'roadMap',
            user = 'app_roadmap',
            password ='MTrmap369',
        },

    },
    zmq = {
        	test = {
            		host = "127.0.0.1",
            		port = 5555,
            		mold = "REQ",
        	},
	},
}


OWN_DIED = {
    redis = {
    },
    mysql = {

    },

    http = {
        -- stored the wav file
        dfsapi_txt2voice = {
            host = '192.168.1.3',
            port = 80,
        },
        dfsapi_save_sound = {
            host = '192.168.1.3',
            port = 80,
        },
        -- send personal weibo
        weiboapi = {
            host = '192.168.1.68',
            port = 8088,
        },
	['weibo-G'] = {
	    host = '192.168.71.196',
	    port = 4070,
	},
	['weibo-S'] = {
	    host = '192.168.71.196',
	    port = 7777,
	},

        -- this is the host and port of callback api
        callbackapi = {
            host = '192.168.1.68',
            port = 8088,
        },


    },
}


setmetatable(_M, { __index = _M })
