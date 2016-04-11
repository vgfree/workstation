
删除用户收藏的新闻接口
====================

### API编号

### 功能简介
* 删除用户收藏的新闻


### 参数格式

* API 以 **POST** 方式请求， 且传送方式为 **key-value** 格式


### 输入参数

  参数名称       |参数说明      |    类型     |是否允许为空     | 限制条件
-----------------|--------------|-------------|-----------------|--------------------
  appKey         |应用标识      | string      |否               | 长度不大于10
  accountid      |安全签名      | string      |否               | 长度为40
  collectid      |收藏新闻的id  | string      |否               | 删除所收藏新闻的ID  > 0

### 代码示例

    POST /deleteCollectionNews HTTP/1.0
    User-Agent: curl/7.33.0
    Host: 127.0.0.1:80
    Connection: close
    Content-Type:application/x-www-form-urlencoded
    Content-Length:96
    Accept: */*
    
    collectid=3&sign=3A8A04704CE8068C55D7F1F4E6EEF4663EEA0371&appKey=1111111111&accountid=eB6bYE8pkl


### 返回body示例

* 出错: {"ERRORCODE":"ME01023", "RESULT":"appKey is error!"}
* 正确: {"ERRORCODE":"0", "RESULT":"3"}


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
RESULT              | 删除的新闻编号


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
 0          | Request OK                |
 ME01002    | appKey error              | appKey需使用从语镜公司申请得到的appKey
 ME01019    | sign not match            | 请阅读语镜公司提供的签名算法
 ME18040    | argument error            | 请检查输入参数


### 测试地址: api.daoke.io/deleteCollectionNews

