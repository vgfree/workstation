
创建集团接口文档
========================

### API编号
* S0224V2

### 功能简介
* 创建一个集团

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数              |参数说明            |  类型       |   示例                    |是否允许为空 |  限制条件
-------------------|--------------------|-------------|---------------------------|-------------|--------------
 appKey            |应用标识            | string      |  1111111111               |否           | 长度小于10
 sign              |安全签名            | string      |  无                       |否           | 长度为40
 groupName         |集团名字            | string      |  mirrtalk                 |否           | 长度不大于32,需URL编码
 accountID         |账户编号            | string      |  aaaaaaaaaa               |否           | 长度为10
 isCarFleet        |该集团是否为车队    | string      |  1                        |是           | 1代表是,0代表不是,默认为1
 isTempGroup       |是否为临时集团      | string      |  0                        |是           | 1是临时集团，0不是临时集团,默认为0
 callbackURL       |回调地址            | string      |  无                       |是           | 允许为空，不为空时长度不能超过512


### 示例代码

    POST /weiboapi/v2/createGroup HTTP/1.0
    Host:192.168.1.0:80
    Content-Length:154
    Content-Type:application/x-www-form-urlencoded
    
    sign=29048BD0D4D2F124B9587E8E0C37AF935F20867C&groupName=liangGeDeGroup&accountID=O40cml0y5p&appKey=1111111111


### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"groupID":"GfQ2XCys8nyHnkGl"}}`


### 返回结果参数

 参数                   | 参数说明
------------------------------------------
 groupID                | 集团编号


### 错误编码

 参数                 | 错误描述                | 解决办法
----------------------|-------------------------|---------------------------------------
 0                    | Request OK              |
 ME01002              | appKey error            | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign not match          | 请阅读语镜公司提供的签名算法
 ME01022              | 服务器内部错误          | 请与公司客服联系
 ME01023              | 参数错误                | 请检查输入参数
 ME18052              | 该集团已存在            | 请与公司客服联系
 ME18053              | 此accountID不存在       | 请与公司客服联系
 ME18075              | 不允许创建集团          | 请与公司客服联系

### 测试地址: api.daoke.io/weiboapi/v2/createGroup

