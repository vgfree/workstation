
审核申请加入集团成员接口文档
========================

### API编号

### 功能简介
* 审核申请加入的集团成员


### 参数格式
* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明                     |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------------------|-------------|----------------|------------|---------------
 appKey           | 应用标识                    | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名                    | string      |  无            |否          | 长度为40
 groupID          | 集团编号                    | string      |  daoke         |否          |
 isCarMember      | 是否是集团成员              | string      |  1             |是          | 0,1
 creatorAccountID | 集团创建者的账户编号        | string      |  aaaaaaaaaa    |否          | 长度为10
 applyAccountID   | 申请加入者的账户编号        | string      |  aaaaaaaaaa    |否          | 长度为10,多个用逗号分隔
 callbackURL      | 回调地址                    | string      |  http://*      |            | 允许为空,不为空是需为http开头,且长度不能超过255， 回调的body中有accountID,name,operationType三个参数.用户帐号,用户昵称,操作类型6代表同意
 yes              | 是否允许加入                | string      |  1             |            | 0,1 ， 1代表确认,0为拒绝


### 示例代码

    POST /weiboapi/v2/verifyApplyJoiningMember HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:148
    Content-Type:application/x-www-form-urlencoded
    
    sign=FD5B57C7A9C4B64C7977E52CB9131646E0DD81BD&groupID=pnlmBtmoFR3IFt7y&yes=1&applyAccountID=kxl1QuHKCD&appKey=1111111111&creatorAccountID=WFlYtlfPlg


### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":[{"accountID":"kxl1QuHKCD","status":0}]}`


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
ccountID            | 账户编号
status              | 加入状态， 0表示未成功， 1表示成功


### 错误编码

 错误编码   | 错误描述                  | 解决办法
------------|---------------------------|------------------
 0          | Request OK                |
 ME01002    | appKey error              | appKey需使用从语镜公司申请得到的appKey
 ME01019    | sign is not match         | 请阅读语镜公司提供的签名算法
 ME01022    | 系统内部错误              | 请与公司客服联系
 ME18023    | 参数错误                  | 请检查输入参数


### 测试地址: api.daoke.io/weiboapi/v2/verifyApplyJoiningMember

