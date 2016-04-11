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
		statistic = {
			host = '192.168.1.11',
			port = 6339,
		},
		weibo = {
			host = '192.168.1.11',
			port = 6329,
		},
		--格网迁移 jiang z.s. 2014-04-09
		mapGridOnePercent = {
			host = "192.168.1.10",
			port = 5071,
		},
	},
	mysql = {
		--- 用户自定义 
		app_custom___wemecustom = {
			host = '192.168.1.6',
			port = 3306,
			database = 'WEMECustom',
			user = 'app_custom',
			password ='appCu159',
		},
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
		app_clientmirrtalk___clientmirrtalk = {
			host = '192.168.1.6',
			port = 3306,
			database = 'client_mirrtalk',
			user = 'observer',
			password = 'abc123',
		},
	},
}

OWN_DIED = {
	redis = {
	},
	mysql = {
	},
	http = {
		---- 
		weiboServer = { host = "192.168.1.3", port = 8088 },

		-- dfsapi,文本转语音
		txt2voice   = { host = '192.168.1.207',port = 80 },

		batchFollowMicroChannel   = { host = 'api.daoke.io',port = 80 },

		userKeyServer =  { host = '127.0.0.1',port = 80 },

		clientCustom =  { host = '127.0.0.1',port = 80 },
		
	}
}


setmetatable(_M, { __index = _M })
