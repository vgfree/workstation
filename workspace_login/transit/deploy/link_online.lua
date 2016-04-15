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
		read_private = {
			host = '172.16.71.93',
			port = 6319,
		},
		weibo = {
			host = 'weibo.redis.daoke.com',
			port = 6329,
		},
		---- 新版weibo的redis
		weiboNew = {
			host = '172.16.51.23',
			port = 80,
		},
		statistic = {
			host = 'statistic.redis.daoke.com',
			port = 6339,
		},
		
		
		---- 数据部门使用的redis服务器 2014-11-26 
		dataCore_redis = {
			host = 'dataCore.redis.daoke.com',
			port = 6359,
		},

		tsdb_hash = {
			-- hash模式consistent／customer
			-- hash = 'consistent',
			hash = 'customer',
                        {'M', 'a0', 'tsdb1.redis.daoke.com', 7000, 30},
                        {'M', 'a1', 'tsdb1.redis.daoke.com', 7001, 30},
                        {'M', 'a2', 'tsdb1.redis.daoke.com', 7002, 30},
                        {'M', 'a3', 'tsdb1.redis.daoke.com', 7003, 30},
                        {'M', 'a4', 'tsdb1.redis.daoke.com', 7004, 30},
                        {'M', 'a5', 'tsdb1.redis.daoke.com', 7005, 30},
                        {'M', 'a6', 'tsdb1.redis.daoke.com', 7006, 30},
                        {'M', 'a7', 'tsdb1.redis.daoke.com', 7007, 30},
                        {'M', 'a8', 'tsdb1.redis.daoke.com', 7008, 30},
                        {'M', 'a9', 'tsdb1.redis.daoke.com', 7009, 30},
		},
	
		message_hash = {
			-- hash模式consistent／customer
			-- hash = 'consistent',
			hash = 'customer',
                        {'M', 'b0', 'weibodata.redis.daoke.com', 9023, 30},
                        {'M', 'b1', 'weibodata.redis.daoke.com', 6329, 30},
                        {'M', 'b2', 'weibodata.redis.daoke.com', 6329, 30},
                        {'M', 'b3', 'weibodata.redis.daoke.com', 6329, 30},
		},
		---- 大坝redis协议
		damServer = {
			host = "dams.server.daoke.com",
			port = 4210,
		},

		---- 广告的redis-key服务器 2015-06-03
		adTalkServer = {
			host = "shengcai.redis.daoke.com",
			port = 6600,
		},
		amrBinary = {
                        host = "tmpvoice.redis.daoke.com",
                        port = 9023,
                },

	},
	mysql = {
		----add by jiang z.s. daokeIO
		app_url___url = {
			host = 'db1.mysql.daoke.com',
			port = 3306,
			database = 'url',
			user = 'app_url',
			password ='DKurlLog159',
    		},
		app_ns___newStatus = {
			host = 'db1.mysql.daoke.com',
			port = 3306,
			database = 'newStatus',
			user = 'app_ns',
			password ='DKnsMSG110',
    		},
    		----add by jiang z.s. daokeIO
		app_mirrtalk___config = {
			host = 'db2.mysql.daoke.com',
			port = 3306,
			database = 'config',
			user = 'app_mirrtalk',
			password ='102cfgDK',
		},
		----add by jiang z.s. daokeIO
		app_identify___coreIdentification = {
			host = 'db2.mysql.daoke.com',
			port = 3306,
			database = 'coreIdentification',
			user = 'app_identify',
			password ='coreDK357',
		},
		----add by jiang z.s. daokeIO
		app_fb___feedback = {
			host = 'db1.mysql.daoke.com',
			port = 3306,
			database = 'feedback',
			user = 'app_fb',
			password ='DKfback147',
		},
		app_weibo___weibo_read = {
			host = 'db3.mysql.daoke.com',
			port = 3307,
			database = 'app_weibo_read',
			user = 'app_weibo',
			password ='258MTweibo',
		},

		------------------begin-------------------------------
		------------------2014-06-19 jiang z.s. --------------
		----- 只有工程模式才启用以下内容 ----------------------
		app_url___url_gc = {
			host = 's9gc.mysql.daoke.com',
			port = 3306,
			database = 'url_gc',
			user = 'app_url',
			password ='DKurlLog159',
    		},
    		app_mirrtalk___config_gc = {
			host = 's9gc.mysql.daoke.com',
			port = 3306,
			database = 'config_gc',
			user = 'app_mirrtalk',
			password ='102cfgDK',
		},
		----- 只有工程模式才启用以上内容 ----------------------
		------------------end-------------------------------
		
		---- adTalk 2015-06-05
		app_adtalk___readAdTalkInfo= {
			host = 'db1.mysql.daoke.com',
			port = 3306,
			database = 'app_shengcai',
			user = 'app_adtalk',
			password ='appaabc123',
		},
	
	},
}


OWN_DIED = {
	redis = {
	},
	mysql = {
	},

	http = {
		----DFS文件上传配置jiang z.s.
		dfsSaveSound = {
			host = 'dfsapi.server.daoke.com',
			port = 80,
		},

		----feedback下发api jiang z.s. 
		feedbackDispatch = { 
			host = 'feedbackapi.server.daoke.com',
			port = 80,
		},
		---- 地图API入口 jiang z.s.
		MDDS = {
			host = 'mdds.server.daoke.com',
			port = 80,
		},

		---- 数据分发给MMR
		MMR = {
			host = 'mmr.server.daoke.com',
			port = 4040,
		},

		supeX = {
			host = "supex.server.daoke.com",
			port = "4040",
		},

		---- 分析数据中心2014-09-26 powerOn Status
		dataCore  = { 
			host = 'datacore.server.daoke.com', 
			port = 9098,
		},

		---- 算法部门业务 2014-10-09
		roadRank = {
			host = "roadrank.server.daoke.com",
			port = "4100",
		},

		---- 大坝数据中心
		damServer = {
			host = "dams.server.daoke.com",
			port = 4210,
		},
		---- 下发微博
		saveWeiboServer = {
			host = "192.168.1.192",
			port = 80,
		},

		---- 读取微博
		readWeiboServer = {
			host = "192.168.1.192",
			port = 80,
		},

	}
}


setmetatable(_M, { __index = _M })
