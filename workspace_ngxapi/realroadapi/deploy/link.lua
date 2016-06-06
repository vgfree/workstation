module(..., package.seeall)

OWN_POOL = {
	redis = {
		private = {
			host = '192.168.71.84',
			port = 6319,

		},
		public = {
			host = '172.16.71.84',
			port = 6349,

		},
		realroad = {
			host = '172.16.51.213',
			port = 6379,

		},


	},
	mysql = {
		login_config___config = {
			host = 'db4.mysql.daoke.com',
			port = 3306,
			database = 'app_roadEyes',
			user = 'app_Reyes',
			password ='f1Rs08Dk',
		},
		weme_car___car = {
			host = 'db2.mysql.daoke.com',
			port = 3306,
			database = 'weme_car',
			user = 'app_Reyes',
			password ='f1Rs08Dk',
		},
		update_info___info = {
			host = 'db2.mysql.daoke.com',
			port = 3306,
			database = 'weme_car',
			user = 'app_Reyes',
			password ='f1Rs08Dk',
		},
	}
}

OWN_DIED = {
	redis = {

	},
	mysql = {
	},

	http = {
		refreshTrustAccessToken = {
			host = "172.16.51.17",
			port = 80
		},
	}

}


setmetatable(_M, { __index = _M })
