module(..., package.seeall)

OWN_POOL = {
	redis = {
		public = {
			host = '192.168.1.11', 
			port = 6349,
		},
		readgpsdata = {
			host = '192.168.1.11', 
			port = 6319,
		},
		saveTokencode = {
			host = '192.168.1.11', 
			port = 6349,
		},

		private = {
			host = '192.168.1.11',
			port = 6319,
		},

		read_private = {
			host = '192.168.1.11',
			port = 7319,
		},

		weibo = {
			host = '192.168.1.11',
			port = 6329,
		},

		---- 新版weibo的redis
		weiboNew = {
			host = '192.168.1.192',
			port = 6379,
		},

		statistic = {
			host = '192.168.1.11',
			port = 6339,
		},

		---- 数据部门使用的redis服务器 2014-11-26 
		dataCore_redis = {
			host = '192.168.1.13',
			port = 8001,
		},

		tsdb_hash = {
			-- hash模式consistent／customer
			-- hash = 'consistent',
			hash = 'customer',
                        {'M', 'a0', '192.168.1.12', 7776, 30},
                        {'M', 'a1', '192.168.1.12', 7777, 30},
                        {'M', 'a2', '192.168.1.12', 7778, 30},
                        {'M', 'a3', '192.168.1.12', 7779, 30},
                        {'M', 'a4', '192.168.1.12', 7776, 30},
                        {'M', 'a5', '192.168.1.12', 7777, 30},
                        {'M', 'a6', '192.168.1.12', 7778, 30},
                        {'M', 'a7', '192.168.1.12', 7779, 30},
                        {'M', 'a8', '192.168.1.12', 7776, 30},
                        {'M', 'a9', '192.168.1.12', 7777, 30},
		},
		url_hash = {
			-- hash模式consistent／customer
			-- hash = 'consistent',
			hash = 'customer',
                        {'M', 'a0', '192.168.1.12', 8000, 30},
                        {'M', 'a1', '192.168.1.12', 8001, 30},
                        {'M', 'a2', '192.168.1.12', 8002, 30},
                        {'M', 'a3', '192.168.1.12', 8003, 30},
                        {'M', 'a4', '192.168.1.12', 8004, 30},
                        {'M', 'a5', '192.168.1.12', 8005, 30},
                        {'M', 'a6', '192.168.1.12', 8006, 30},
                        {'M', 'a7', '192.168.1.12', 8007, 30},
                        {'M', 'a8', '192.168.1.12', 8008, 30},
                        {'M', 'a9', '192.168.1.12', 8009, 30},
		},
	
		message_hash = {
			-- hash模式consistent／customer
			-- hash = 'consistent',
			hash = 'customer',
                        {'M', 'b0', '127.0.0.1', 6379, 30},
                        {'M', 'b1', '127.0.0.1', 6379, 30},
                        {'M', 'b2', '127.0.0.1', 6379, 30},
                        {'M', 'b3', '127.0.0.1', 6379, 30},
		},
		---- 大坝redis协议
		damServer = {
			host = "dams.server.daoke.com",
			port = 4210,
		},
		---- 广告的redis-key服务器 2015-06-03
		adTalkServer = {
			host = "192.168.1.13",
			port = 6379,
		},
		amrBinary = {
                        host = "127.0.0.1",
                        port = 9023,
                },

	},
	mysql = {
		----add by jiang z.s. daokeIO
		app_url___url = {
			host = '192.168.1.6',
			port = 3306,
			database = 'url',
			user = 'app_url',
			password ='DKurlLog159',
    		},
		app_ns___newStatus = {
			host = '192.168.1.6',
			port = 3306,
			database = 'newStatus',
			user = 'app_ns',
			password ='DKnsMSG110',
    		},
    		----add by jiang z.s. daokeIO
		app_mirrtalk___config = {
			host = '192.168.1.6',
			port = 3306,
			database = 'config',
			user = 'app_mirrtalk',
			password ='102cfgDK',
		},
		----add by jiang z.s. daokeIO
		app_identify___coreIdentification = {
			host = '192.168.1.6',
			port = 3306,
			database = 'coreIdentification',
			user = 'app_identify',
			password ='coreDK357',
		},
		----add by jiang z.s. daokeIO
		app_fb___feedback = {
			host = '192.168.1.6',
			port = 3306,
			database = 'feedback',
			user = 'app_fb',
			password ='DKfback147',
		},
		app_weibo___weibo_read = {
			host = '192.168.1.6',
			port = 3306,
			database = 'app_weibo_read',
			user = 'app_weibo',
			password ='258MTweibo',
		},

		------------------begin-------------------------------
		------------------2014-06-19 jiang z.s. --------------
		----- 只有工程模式才启用以下内容 ----------------------
		app_url___url_gc = {
			host = '192.168.1.6',
			port = 3306,
			database = 'url_gc',
			user = 'app_url',
			password ='DKurlLog159',
    	},

    	app_mirrtalk___config_gc = {
			host = '192.168.1.6',
			port = 3306,
			database = 'config_gc',
			user = 'app_mirrtalk',
			password ='102cfgDK',
		},
		----- 只有工程模式才启用以上内容 ----------------------
		------------------end-------------------------------

		---- adTalk 2015-06-05
		app_adtalk___readAdTalkInfo= {
			host = '192.168.1.6',
			port = 3306,
			database = 'app_adTalk',
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
			host = '192.168.1.6',
			port = 80,
		},

		----feedback下发api jiang z.s. 
		feedbackDispatch = { 
			host = '192.168.1.113',
			port = 80,
		},
		---- 地图API入口 jiang z.s.
		MDDS = {
			host = '192.168.1.3',
			port = 8088,
		},


		---- 数据分发给MMR
		MMR = { 
			host = '192.168.1.102', 
			port = 8080 ,
		},

		supeX = {
			host = "127.0.0.1",
			port = "80",
		},

		---- 分析数据中心2014-09-26 powerOn Status
		dataCore  = { 
			host = '192.168.1.102', 
			port = 80,
		},

		---- 算法部门业务 2014-10-09
		roadRank = {
			host = "192.168.1.14",
			port = "7779",
		},

		---- 大坝数据中心
		damServer = {
			host = "192.168.1.207",
			port = "5000",
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
