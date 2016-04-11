app与WEME连接发送微博接口
========================

### API编号
* 

### 功能简介
* app与WEME连接发送微博接口

### 参数格式

* API以 **POST** 方式请求，且使用form表单方式提交,注意boundary

### 输入参数

 参数                                 | 参数说明           | 类型      |   示例             | 是否允许为空 | 限制条件
--------------------------------------|---------------------|------------|--------------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无                 | 否           | 长度为40
 multimediaURL              | 音频文件链接       | string  |http://xx.com/a.amr | 否    | 无
 accountID                  | 接受者帐号         | string  | 45263212851   | 否           | 
 parameterType              | 参数类型           | string  | 1/2/3         | 否           | 1:接受者的accountID  2:接受者的手机号  3:接受者的IMEI
 level                      | 微博等级           | number  | 20                 | 否           | 邀请微博建议设置为18  正常发微博设置为20
 interval                   | 微博的有效期       | number  | 60                 | 否           | 微博有效期(秒) 
 callbackURL                | 回调地址           | string  | http://xxx.com/te  | 否           | WEME回复的回调地址
 


### 示例代码/clientcustom/v2/appConnectSendWeibo

	POST /clientcustom/v2/appConnectSendWeibo HTTP/1.0
	Host:api.daoke.io
	Content-Length:1220
	Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU

	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="level"
	
	20
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="interval"
	
	6000
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="accountID"

	222222222222222
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="parameterType"

	3
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="multimediaURL"

	http://192.168.1.6/group3/M00/00/1E/wKgBBlO_gmyAYYrYAAAITe8iduk605.amr
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="sign"
	
	3269C312A979E120DA81236D05F91C7F6B7D1419
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="callbackURL"

	http://127.0.0.1/callbackURL
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU
	Content-Disposition: form-data; name="appKey"

	1111111111
	------WebKitFormBoundaryDcO1SS14074119076310460MTDfpuu1407411907kkU--


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"bizid":"a4f274f2521e2711e4a974002219522239"}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回参数

 参数      |  参数描述 
-----------|----------------
  bizid   | 发送微博返回的唯一标识


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01004              | accessToken expire     | 访问令牌已过期
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME18005              | 不存在此字段           | 请检查输入参数
 ME18006              | 帐号未绑定IMEI        | 需要通过app绑定IMEI
 ME18068              | 手机号不正确           | 需要绑定手机号
 ME18091              | WEME未设置+键         | 需要通过app设置+键为连线


### 测试地址: api.daoke.io/clientcustom/v2/appConnectSendWeibo


