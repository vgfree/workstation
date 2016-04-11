
根据频道编码获取频道详情信息
========================

### API编号
* 

### 功能简介
* 根据频道编码获取频道详情信息

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                        | 参数说明           | 类型    |   示例             | 是否允许为空  | 限制条件
-----------------------------|-------------------|--------|--------------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111         | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无                 | 否           | 长度为40
 accountID                  | 申请账户           | string  | aaaaaaaaaa         | 否           | 长度为10 
 channelNumber              | 频道编号           | string  | FM000004           | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母	
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |

代码示例： 
	POST /clientcustom/v2/getMicroChannelInfo HTTP/1.0
	Host:api.daoke.io
	Content-Length:107
	Content-Type:application/x-www-form-urlencoded

	appKey=1111111111&sign=329BAFCF61BA3054D6D48C60473A9CC109DFF0D3&accountID=aaaaaaaaaa&channelNumber=A111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":[{"keyWords":"测试车市,abc","createTime":"1433411054","cityName":"安阳市","introduction":"特殊频道","channelStatus":"2","accountID":"aaaaaaaaa","logoURL":"http:\/\/baidu.jpg","chiefAnnouncerIntr":"小喇叭小小小小小喇叭","catalogID":"111111","InviteUniqueCode":"FM999999|4d2a1ce60a9e11e5a726000c29434c94","idx":"843","chiefAnnouncerName":"","catalogName":"美女要不要","userCount":"0","cityCode":"111111","onlineCount":0,"validity":0,"name":"测试用品"}]}`
* 失败: 
		`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

参数     		 | 参数说明
-----------------|--------------------------------
validity 		 | 关注状态
InviteUniqueCode | 频道邀请码
keyWords 		 | 频道关键字
createTime 		 | 创建时间
idx 	  		 | 频道真实号码
cityName  		 | 城市名称
introduction  	 | 频道简介
channelStatus 	 | 频道状态
catalogName   	 | 频道类别
cityCode 	  	 | 城市区域编号
logoURL 	  	 | 频道logo
chiefannouncerIntr | 频道主播简介
name 		  	 | 频道名称
catalogID 		 | 频道类别编号
chiefAnnouncerName | 主播名
userCount 		|关注频道用户数
onlineCount   | 频道在线用户数

### 错误编码

 参数                 | 错误描述                 | 解决办法     
----------------------|-------------------------|---------------------------------------
 0                    | ok 	                    | 调用成功
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error            | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match       | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!    | 系统错误，请与公司客服联系
 ME01020              | mysql failed!			| 数据库错误 ,请与公司客服联系
 ME01024              | http body is null!		| 请检查配置文件，请与公司客服联系
 ME01023              | parameter is error!     | 参数错误，请按照文档提供的参数要求传参
 ME18109              | channel number is error | 频道编码不存在 ,请与公司客服联系 

### 测试地址: api.daoke.io/clientcustom/v2/getMicroChannelInfo


