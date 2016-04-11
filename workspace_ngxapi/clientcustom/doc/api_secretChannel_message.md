群聊频道消息提醒
========================

### API编号
* 

### 功能简介
* 群聊频道消息提醒
### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明            | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|----------------------|----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       	| 安全签名           | string  | 无            | 否           | 长度为40
 accountID                 	| 管理员的帐户编号	  | string  | aaaaaaaaaa    | 否           | 长度为10的字母
 status                 	| 消息状态	  | int  | 1    |  是          | 不能有小数点 0未处理  1接收  2 拒绝
 startPage                 	| 起始索引           | int      | 1     		| 是           | 不能有小数点 
 pageCount                 	| 每页显示条数       | int      | 1     		| 是           | 小于500的正整数,不能有小数点
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |

### 示例代码/clientcustom/v2/secretChannelMessage
	POST /clientcustom/v2/secretChannelMessage HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:175
	Content-Type:application/x-www-form-urlencoded

	appKey=1111111111&pageCount=20&sign=C63ADE8925F9DA6156391797369A20EABA96D082&startPage=1&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa




### 返回body示例

* 成功:`{"ERRORCODE": "0", "RESULT": {"count": "1","list": [{"number""000000000","applyRemark":"hhhhh","createTime":"1428900968","status": "0","applyAccountID": "aaaaaaaaaa","idx": "5","applyNickname": "山川同学"}]}}`		
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数    | 参数说明
---------|--------------------------------
 count  | 数字 条数 几条记录集
 list    |二维数组,查询返回信息集合 
 createTime|创建时间
 number  |频道编号
 applyRemark|申请备注
 status|状态 0未处理  1接收  2 拒绝
 applyAccountID|申请人
 applyNickname|申请人昵称
 idx|编号



### 错误编码

 参数                  | 错误描述              		| 解决办法     
-----------------------|-------------------------------|---------------------------------------
 0                     | ok              	  		| 调用成功
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01002              | appKey error         	  	| appKey需使用从语镜公司申请得到的appKey
 ME01023              | accountid is error!    	| 请与公司客服联系
 ME01020              | mysql failed!        	  	| 访问令牌已过期
 ME01019              | sign is not match      	| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error    	| 请与公司客服联系
 ME01023              | args is error!      		| 参数错误，请检查参数
 ME18053              |this accountID is not exist!	  |当前的用户编号不存在 ,请重新输入


 


### 测试地址: api.daoke.io/clientcustom/v2/fetchSecretChannel


