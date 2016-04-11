
获取申请加入集团的待审核成员接口文档
========================

### API编号

### 功能简介
* 获取申请加入集团的待审核成员

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数              |参数说明     |  类型       |   示例         |  限制条件
-------------------|-------------|-------------|----------------|--------------
 appKey            |应用标识     | string      |  1111111111    | 长度小于10
 sign              |安全签名     | string      |  无            | 长度为40
 groupID           |集团标识     | string      |  mirrtalk      | 长度不大于16
 accountID         |用户帐号编号 | string      |  aaaaaaaaaa    | 长度为10


### 示例代码

    POST /weiboapi/v2/fetchApplyJoiningMember HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:109
    Content-Type:application/x-www-form-urlencoded
    
    sign=C9FFDA83C0ABC4A3A1EB4E02F021B9A281728E49&groupID=pnlmBtmoFR3IFt7y&accountID=WFlYtlfPlg&appKey=1111111111


### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":[{"accountID":"kxl1QuHKCD","name":"晓天哥"}]}`


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
accountID           | 用户帐号编号
name                | 用户名

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
 0          | Request OK                |
 ME01002    | appKey error              | appKey需使用从语镜公司申请得到的appKey
 ME01019    | sign not match            | 请阅读语镜公司提供的签名算法
 ME01022    | 服务器内部错误            | 请与公司客服联系
 ME01023    | 参数错误                  | 请检查输入参数
 ME18054    | 该集团不存在              | 请与公司客服联系
 ME18055    | 该集团不可加入            | 请与公司客服联系

### 测试地址: api.daoke.io/weiboapi/v2/fetchApplyJoiningMember

