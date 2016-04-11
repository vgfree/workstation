
获取用户按键自定义接口
========================

### API编号
* 

### 功能简介
* 获取用户按键所设置的参数

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型    |   示例        | 是否允许为空 | 限制条件
----------------------------|--------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 用户帐号           | string  | 2222222222    | 否           | 长度为10 
 actionType                 | 按键类型           | string  | 4或者5        |  是          | 值:4-语音命令(对应+键),5-发送群组语音(对应++键)
 accessToken                | 用户的授权访问令牌 | string  | 无            |  否          | 无





### 示例代码/clientcustom/v2/getCustomInfo

    POST /clientcustom/v2/getCustomInfo HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    sign=5B46385253602C9079F95728D7717A9ADDC587A6&accountID=2222222222&appKey=1111111111&accessToken=sadfsdfsdaf


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"count":"2","list":[{"actionName":"voiceCommand","customParameter":"","customType":"1","actionType":"4"},{"actionName":"groupVoice","customParameter":"00008","customType":"1","actionType":"5"}]}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数   | 参数说明
---------|--------------------------------
 actionName      | 按键名词(英文)
 customParameter | 按键所设置的值
 actionType      | 按键类型值
 customType      | 按键所设置功能类型
 

### 特殊业务
目前至此+,++按键自定义如下

actionType|  按键  | customType    |  功能说明      | customParameter  |  参数说明
--------|----------|-------|----------------|------------------|----------------
  4     | + 按键   |  1    |   语音记事本  |    X         |  返回空
  4     | + 按键   |  2    |   设置频道    |    88888     |  所设置频道ID
  4     | + 按键   |  5    |  app家人连线  |    X         |  返回空
  4     | + 按键   |  6    |  密频道       |  密频道编码  |  密频道编号 [*暂时未使用]
  5     |++ 按键   |  1    |   设置频道    |    88888     |  所设置频道ID
  5     |++ 按键   |  2    |  密频道       |  密频道编码  |  密频道编号 [*暂时未使用]

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


### 测试地址: api.daoke.io/clientcustom/v2/getCustomInfo


