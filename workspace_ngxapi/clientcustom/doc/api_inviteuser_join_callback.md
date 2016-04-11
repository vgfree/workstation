
发送微博邀请用户加入xx功能
========================

### API编号
* 

### 功能简介
* 发送微博邀请用户加入xx功能,具体实现功能,根据callbackURL回调地址

### 参数格式

* API以 **POST** 方式请求，且使用form表单方式提交,注意boundary

### 输入参数

 参数                                 | 参数说明           | 类型      |   示例             | 是否允许为空 | 限制条件
--------------------------------------|---------------------|------------|--------------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无                 | 否           | 长度为40
 accountID                  | 语镜用户帐户编号  | string  | 2222222222    | 否           | 长度为10的字母
 tempChannelID              | 临时频道           | string  | 0123520       | 否           | 长度为5~8位的数字(允许0开头)
 multimediaURL              | 多媒体链接         | string  | http://xxx.amr| 否           | 必须为amr文件,有效音频
 callbackURL                | 回调地址           | string  | http://aaa.amr| 否           | 业务回调地址(可能带参数,计算签名使用原始字符串,计算完毕需要转为URL编码)

### 示例代码/clientcustom/v2/inviteUserJoin

    POST /clientcustom/v2/inviteUserJoin HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:1049
	Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU

	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU
	Content-Disposition: form-data; name="accountID"

	2222222222
	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU
	Content-Disposition: form-data; name="appKey"

	1111111111
	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU
	Content-Disposition: form-data; name="multimediaURL"

	http://192.168.1.6/group3/M00/00/1E/wKgBBlO_gmyAYYrYAAAITe8iduk605.amr
	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU
	Content-Disposition: form-data; name="sign"

	7B33BF0728EFC514D8665A62E1413DA84B31B225
	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU
	Content-Disposition: form-data; name="callbackURL"

	http://192.168.11.159:80/inviteToTempChannelCallback?inviteAccountID=anjiklmkin&inviteTempChannelID=12349
	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU
	Content-Disposition: form-data; name="tempChannelID"

	12349
	------WebKitFormBoundaryDcO1SS14074125403019190MTDfpuu1407412540kkU--


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"count":1}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数   | 参数说明
---------|--------------------------------
 count      | 数字 显示发送邀请微博成功的条数

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


### 测试地址: api.daoke.io/clientcustom/v2/inviteUserJoin


