
删除集团成员接口文档
========================

### API编号

### 功能简介
* 删除集团的成员

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数              |参数说明            |  类型       |   示例                    |是否允许为空 |  限制条件
-------------------|--------------------|-------------|---------------------------|-------------|--------------
 appKey:           |应用标识            | string      |  1111111111               |否           | 长度小于10
 sign:             |安全签名            | string      |  无                       |否           | 长度为40
 groupID           |集团编号            | string      |  mirrtalk                 |否           | 长度不大于32
 applyAccountID    |提出申请者账户编号  | string      |  adedfeqweo               |否           | 长度为10
 deleteAccountID   |被删除者账户编号    | string      |  adedfeqweo               |否           | 长度为10


### 示例代码

    POST /weiboapi/v2/deleteGroupMember HTTP/1.0
    Host:192.168.1.0:80
    Content-Length:154
    Content-Type:application/x-www-form-urlencoded
    
    sign=29048BD0D4D2F124B9587E8E0C37AF935F20867C&groupID=group1&deleteAccountID=O40cml0y5p&applyAccountID=O40cml0y5p&appKey=1111111111


### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
无                  | 无


### 错误编码

 错误编码   | 错误描述                  | 解决办法
------------|---------------------------|------------------
 0          | Request OK                |
 ME01002    | appKey error              | appKey需使用从语镜公司申请得到的appKey
 ME01019    | sign not match            | 请阅读语镜公司提供的签名算法
 ME01022    | 服务器内部错误            | 请与公司客服联系
 ME01023    | 参数错误                  | 请检查输入参数
 ME18025    | 删除成员数量达到限制      | 请与公司客服联系
 ME18013    | 该用户不能被删除          | 请与公司客服联系
 ME18056    | 申请者不是集团成员        | 请与公司客服联系
 ME18057    | 没有删除权限              | 请与公司客服联系
 ME18058    | 被删除者不是集团成员      | 请与公司客服联系


### 测试地址: api.daoke.io/weiboapi/v2/deleteGroupMember


