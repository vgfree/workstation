
多媒体在线城市集团微博接口文档
====================

### API编号

### 功能简介
* 向用户终端发送微博消息


### 参数格式
* 所有 API 都以 **POST** 方式请求，且传送方式为 **表单**.


### 输入参数

 参数             |参数说明           |  类型       |   示例         |是否允许为空|  限制条件
------------------|-------------------|-------------|----------------|------------|---------------
 appKey           | 应用标识          | string      | 1111111111     |否          | 长度不大于10
 sign             | 安全签名          | string      | 无             |否          | 长度为40
 regionCode       | 城市编号          | string      | 无             |否          |
 groupID          | 集团编号          | string      | daoke          |否          |
 interval         | 微博有效时长      | string      | 12             |否          | 大于0，单位：s
 level            | 微博的优先级      | string      | 10             |是          | 0-99， 0:优先级最高，99:优先级最低
 multimediaURL    | 多媒体文件URL地址 | string      | 无             |是          | 仅支持音频
 multimediaFile   | 多媒体文件流      | binary      | 无             |是          | 仅支持音频，multimediaURL和multimediaFile二者必选其一
 senderAccountID  | 发送者编号        | string      | aaaaaaaaaa     |是          | 长度为10
 checkTokenCode   | 是否检验tokenCode | string      | 1              |是          | 0,1  0：不检查，1：检查
 callbackURL      | 回调URL           | string      | 无             |是          |
 senderLongitude  | 发送者经度        | string      | 30.11          |是          | -90~90
 senderLatitude   | 发送者纬度        | string      | 121.22         |是          | 0-360
 senderAltitude   | 发送者海拔        | string      | 50             |是          | 大于0
 senderDirection  | 发送者有效方向角  | json array  | [10]           |是          | 0-360, -1
 senderSpeed      | 发送者有效的速度  | json array  | [1,90]         |是          | 数组有1个或2个值
 receiverLongitude| 终端有效经度      | string      | 30.11          |是          | -90~90
 receiverLatitude | 终端有效纬度      | string      | 121.22         |是          | 0-360
 receiverDistance | 终端有效距离      | string      | 50             |是          | 大于0
 receiverDirection| 终端接收方向角    | json array  | [130,10]       |是          | 0-360, -1。方向角及允许误差(方向范围:0~360),格式为json数组，-1表示未得到方向角，正北方向为0度，顺时>针方向为正，保留小数点后3位,第二个json元素代表误差
 receiverSpeed    | 终端接收速度      | json array  | [1,90]         |是          | 数组有1个或2个值，若只有一个数，则表示大于此速度，若有两个数则表示速度范围


### 示例代码

    POST /weiboapi/v2/sendMultimediaGroupWeibo HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:462
    Content-Type:content-type:multipart/form-data;boundary=abc

    --abc
    Content-Disposition:form-data;name="groupID"

    mirrtalkAll
    --abc
    Content-Disposition:form-data;name="regionCode"

    110000
    --abc
    Content-Disposition:form-data;name="senderAccountID"

    lAmQoflGq1
    --abc
    Content-Disposition:form-data;name="multimediaURL"

    http://192.168.1.3:80/helo.wav
    --abc
    Content-Disposition:form-data;name="sign"

    26A87795F0F2A0F56E4E5BA641DB5105ABF5B994
    --abc
    Content-Disposition:form-data;name="appKey"

    2064302565
    --abc
    Content-Disposition:form-data;name="interval"

    25000
    --abc--


### 返回body示例

* 正确: `{"ERRORCODE":"0","RESULT":{"bizid":"aXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}}`
* 出错: `{"ERRORCODE":"ME01002","RESULT":"appkey error"}`



### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
bizid               | 微博返回编号


### 错误编码

 错误编码   | 错误描述                  | 解决办法
------------|---------------------------|------------------
 0          | Request OK                |
 ME01002    | appKey error              | appKey需使用从语镜公司申请得到的appKey
 ME01019    | sign is not match         | 请阅读语镜公司提供的签名算法
 ME01022    | 系统内部错误              | 请与公司客服联系
 ME18023    | 参数错误                  | 请检查输入参数


### 测试地址: api.daoke.io/weiboapi/v2/sendMultimediaOnlineGroupWeibo
