
获取按键定义API
========================

### API编号
* 

### 功能简介
* 获取按键定义API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string   | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string   | 无            | 否           | 长度为40
 startPage					| 开始页             | string   | 无            | 否           | number类型
 pageCount					| 页数量             | string   | 无            | 否           | number类型
 defineName					| 频道名             | string   | 无            | 是           | 长度小余等于64
 actionType					| 作用类型           | number   | 3             | 是           | 3,4,5  3：吐槽按键 4：语音命令 5：群组语音
 customType					| 服务频道ID         | number   | 13             | 是          | 大于等于10的整数
 isDetail					| 返回菜单的标识           | number   | 1             | 是           | 如需返回菜单的内容，必填写1


### 示例代码/clientcustom/v2/getCustomDefineInfo

    POST /clientcustom/v2/getCustomDefineInfo HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    appKey=2064302565&pageCount=1&customType=&sign=D51FFA2133C557845513CB40EADB7F07158D459C&actionType=&startPage=1&defineName=%E8%B7%AF%E5%86%B5%E5%88%86%E4%BA%AB&isDetail=


### 返回body示例

* 成功: `{"ERRORCODE": "0","RESULT": {"count": "1","list": [{"isSystem": "1","actionType":"3","briefIntro":"一键分享你的路况,让更多人来吐槽","defineLogo": "","customType": "10","defineName":"路况分享","codeMenu": ""}]}}`
* 失败: `{"ERRORCODE":"ME01023", "RESULT":"parameter is error!"}`



### 返回结果参数

参数                  | 参数说明              
----------------------|----------------------------------------------
count                 | 目录数量
isSystem              | 是否系统
defineLogo            | 定义图标链接
actionType            | 按键类型。3：吐槽按键 4：语音命令 5：群组语音
defineName            | 频道名（如路况分享/语音记事本/家人连线等）
customType            | 服务频道ID
codeMenu            | 菜单
briefIntro            | 频道简介

### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | Request OK                     | 正常调用
 ME01023              | parameter is error!            | 请按照文档提供的参数要求传参
 ME01020              | mysql failed!                  | 请与公司客服联系
 ME01022              | internal data error!           | 请与公司客服联系
 ME01024              | http body is null!             | 请与公司客服联系


### 测试地址: api.daoke.io/clientcustom/v2/getCustomDefineInfo

