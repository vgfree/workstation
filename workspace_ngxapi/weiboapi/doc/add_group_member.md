
添加微博集团成员接口文档
========================

### API编号

### 功能简介
* 向某集团添加成员


### 参数格式

 参数              |参数说明    |  类型       |   示例         |是否允许为空    |  限制条件
-------------------|------------|-------------|----------------|----------------|--------------
 appKey            |应用标识    | string      |  1111111111    |否              | 长度小于10
 sign              |安全签名    | string      |  无            |否              | 长度为40
 groupID           |集团标识    | string      |  mirrtalk      |否              | 长度不大于16
 isCarMember       |是否车队成员| string      |  1             |否              | 0表示accountID不是车队成员，1表示accountID是车队成员
 accountID         |账户编号    | string      |  aaaaaaaaaa    |否              | 长度为10
 feedbackURL       |回调地址    | string      |  http://*      |是              | 不为空是需为http开头,且长度不能超过255

### 示例代码

    POST /weiboapi/v2/addGroupMember HTTP/1.0
    Host:192.168.1.3:80
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded
    
    appKey=1111111111&sign=8CE0AB8644DA9A2FFB0B19CDD3717BD6A010D730&groupID=group1&isCarMember=1&acountID=AuzQWtzGIK


### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`


### 返回结果参数

 参数                   | 参数说明
------------------------|------------------
 无                     | 无


### 错误编码

 参数           | 错误描述              | 解决办法
----------------|-----------------------|---------------------------------------
 0              | Request OK            |
 ME01002        | appKey error          | appKey需使用从语镜公司申请得到的appKey
 ME01019        | sign not match        | 请阅读语镜公司提供的签名算法
 ME01022        | 服务器内部错误        | 请与公司客服联系
 ME01023        | 参数错误              | 请检查输入参数
 ME18006        | 该用户未绑定IMEI      | 请与公司客服联系
 ME18053        | 该用户不存在          | 请与公司客服联系
 ME18054        | 该集团不存在          | 请与公司客服联系
 ME18055        | 该集团不可加入        | 请与公司客服联系
 ME18064        | 用户已经存在集团      | 请与公司客服联系


### 测试地址: api.daoke.io/weiboapi/v2/addGroupMember

