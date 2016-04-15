===============================

---> active的修改
	[@张洁亮]
	在robais中，当active收到userid=GUEST的时候，把该用户的model导入redis,key为userid:model其中(userid为变量)，
	之前robais出现过，tokencode 4至5秒后才能导入redis,不确定还是否存在这个问题，设计问题，询问赵文龙。（个人不建议）
	[@钱慧奇]
	在active中，检查robais的返回状态，失败，返回400,记录错误日志。

---> config的修改
	[@钱慧奇]
	数据库中表configInfo修改为basicConfig,replyConfig,TTSText,TTSConfig，accountID, TSPLocation这几个字段，
	
	basicConfig格式如下：（两个%s必须保留）
	|u=1|vn=01001|sos=10086|callcenter=13917951002|gx=3.0|gy=3.0|gz=3.0|fngps=5|fngsensor=1|domain=192.168.1.6|port=80|userid=%s|status=0|code=%s|
	replyConfig格式如下：
	collectdataperiod=15|newstatusperiod=5|replyUrl=xxxx|autoAnswer=xxxxx|
	TTSConfig格式如下：
	TTS_LANG=%s|TTS_TEXT_MARK=%s|TTS_USE_PROMPTS=%s|TTS_READ_AS_NAME=%s|TTS_READ_DIGIT=%s|TTS_SPEAK_STYLE=%s|TTS_VOICE_SPEED=%s|TTS_VOICE_PITCH=%s|TTS_VOLUME=%s|TTS_VEMODE=%s|
	TTSText格式如下：
	StartupTTS=您的语镜已启动,正在连接系统|CallOutByOne=正在接通服务中心,请稍候|CallOutByFour=求救信息已发出,马上为您报警|InitiativeYes=路过一下|CallInTTS=您有新来电,请注意安全驾驶|CallInTTS=您有新来电,请注意安全驾驶|LowBattery=电量低,请充电|ShutdownTTS=您的语镜已关闭,请检查门窗车灯|ConfirmShutdown=语镜将在30秒后关闭，按功能键二打断|NoNetwork=无法连接您的移动运营商|NoSimCard1=插入手机卡|NoSimCard2=请插入手机卡|NoSimCard4=找不到手机卡|
	
	根据userid:model判断是G网还是C网,原有G网下发信息保持不变，直接basicConfig取出来即可。
	C网时追加下发replyConfig,TTSText,TTSConfig字段。（所有字段用utf8编码）
	检查robais的返回状态，失败，返回200,记录错误日志。

---> newstatus的修改 
	[@钱慧奇]
	表app_weibo修改为app_weibo_read
	当model不为MT801且没有weibo时，返回555错误碼。
	当model不为MT801且weibo中的attribute参数不为空时，追加下发attribute的字段值。

---> yes的修改
	[@钱慧奇]
	redis和mysql操作改为长连接方式，
	根据userid AND bizid AND randomCode，去bizid对应的read库更新readStatus为1
	对应关系如下：
	a1 = 'readSystemWeibo'
	a2 = 'readGroupWeibo'
	a3 = 'readPersonalWeibo'
	a4 = 'readSharedWeibo'
	a6 = 'readSharedWeibo'
	a5 = 'readSubscribedWeibo'
	a7 = {'readPersonalWeibo', 'readSystemWeibo'}
