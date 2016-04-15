module('link', package.seeall)

OWN_POOL = {
	redis = {
		private = {
			host = '192.168.1.11',
			port = 6379,
		},
		statistic = {
			host = '192.168.1.11',
			port = 6379,
		},
		--格网迁移 jiang z.s. 2014-04-09
		mapGrid = {
			host = "192.168.1.10",
			port = 5061,
		},
	},
	mysql = {
		app_daokemap__daokemap_s = {
			host = '192.168.1.3',
			port = 3306,
			database = 'daokeMap',
			user = 'daokemap',
			password ='appdabc123',
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
		dfsTxt2Voice = {
			host = '192.168.1.182',
			port = 80,
		},

		---- 发送个人微博
		personalWeibo = {
			host = '192.168.1.94',
			port = 8088,
		},

		---- 计算用户在线里程 (map)
		lineMileage = {
			host = '192.168.1.3',
			port = 8088,
		},

	}
}

