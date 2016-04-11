增加频道分类接口
========================

### API编号

### 功能简介
* 增加频道分类接口

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型      |   示例               | 是否允许为空 | 限制条件
----------------------------|--------------------|-----------|----------------------|--------------|---------------------------
 appKey                     | 应用标识           | string    | 1111111111           | 否           | 长度不大于10
 sign                       | 安全签名           | string    | 无                   | 否           | 长度为40
 catalogName                | 频道类型名称       | string    | 交通出行             | 否           | 最大10个汉字
 introduction               | 频道类型简介       | string    | 交通出行             | 是           | 无
 catalogType                | 分类类型           | number    | 1                    | 否           | 1:主播频道 2:群聊频道
 validity                   | 是否有效           | number    | 1                    | 是           | 1:开启 0:关闭
 sortIndex                  | 排序索引           | number    | 60                   | 是           | 无
 logoURL                    | 频道分类logourl    | string    | http://www.abc.com   | 是           | 最大128个字符
 


### 示例代码/clientcustom/v2/addChannelCatalog
    POST /clientcustom/v2/addChannelCatalog  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:312
	Content-Type:application/x-www-form-urlencoded

    appKey=1111111111&sortIndex=38&catalogType=2&introduction=交通出行&validity=1&sign=FD4D58B7FE59C510C9A30F8474F7C79A78CBBB6C&logoURL=http://www.abc.com&catalogName=交通出行
	

### 返回body示例

* 成功: `{"ERRORCODE": "0","RESULT": {"introduction": "交通出行","catalogName": "交通出行","sortIndex": "38","logoURL": "http://www.abc.com","catalogType": "2","catalogID": 111111,"validity": "1"}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回参数

 参数           |  参数描述 
---------------|----------------
 catalogID     | 频道类型编号
 catalogName   | 频道类型名称
 introduction  | 频道类型简介
 catalogType   | 分类类型
 validity      | 是否有效
 sortIndex     | 排序索引
 logoURL       | 频道分类logourl


### 错误编码

 参数                  | 错误描述                | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功                 | 
 ME01024              |http body is null!      | 系统错误 请与公司客服联系
 ME01020              |mysql failed!           | 数据库出错，请检查参数
 ME01023              |parameter is error!     | 参数错误 请检查输入参数

### 测试地址: api.daoke.io/clientcustom/v2/addChannelCatalog