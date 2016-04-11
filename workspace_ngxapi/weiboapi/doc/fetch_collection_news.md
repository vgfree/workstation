
获取用户收藏的新闻接口
====================

### API编号

### 功能简介
* 获取用户收藏的新闻

### 参数格式

* API 以 **POST** 方式请求， 且传送方式为 **key-value** 格式

### 输入参数

 参数             | 参数说明            |  类型       |   示例         |是否允许为空|  限制条件
------------------|---------------------|-------------|----------------|------------|-----------------
 appKey           | 应用标识            | string      |  1111111111    |否          |  长度不大于10
 sign             | 安全签名            | string      |  无            |否          |  长度为40
 accountid        | 用户帐号编号        | string      |  aaaaaaaaaa    |否          |  长度为10的数字或字母
 keyword          | 收藏新闻的关键字    | string      |  无            |是          |  
 curPage          | 当前返回页数        | string      |  无            |否          |  数字，必须 > 0
 maxecords        | 每页最大条数        | string      |  无            |否          |  数字, 必须 > 0

### 示例代码

    POST /fetchCollectionNews HTTP/1.0
    User-Agent: curl/7.33.0
    Host: 127.0.0.1:80
    Connection: close
    Content-Type:application/x-www-form-urlencoded
    Content-Length:122
    Accept: */*
    
    maxRecords=1&accountid=eB6bYE8pkl&curPage=1&sign=E807837B6360A9D3C9BB9C5B82DC7EA9590D587A&keyword=广东&appKey=1111111111


### 返回body示例

* 出错: `{"ERRORCODE":"ME01023", "RESULT":"appKey is error!"} `
* 正确: `{"ERRORCODE":"0", "RESULT":[{"releaseTime":"1394198957","longitude":"0.0000000","latitude":"0.0000000","collectid":"1","typeName":"网易最新新闻","link":"http:\/\/rss.feedsportal.com\/c\/33390\/f\/628983\/p\/1\/s\/5f62b677\/l\/0Lnews0B1630N0C140C0A30A80C0A50C9MPRISSP0A0A0A1124J0Bhtml\/story01.htm","title":"广东发改委主任：广东收入分配改革方案将出炉","createTime":"2014-03-17 15:22:52","tokenCode":"78965412ad","bizid":"a3e54e7276ada011e39201002219522239","sourceID":"531d24e1fe6d64243740ccfd","description":"◎企业投资准入负面清单明确禁止类项目、限制类项目(含国家和省有特定准入条件要求的项目)。◎审批事项标准化清单将企业投资项目中，限制类项目核准全过程涉及的审批事项列出清单。◎事中事后监管清单明确相关部门监管责任、监管范围、监管内容和监管程序，形成监管清单。昨日，全国人大代表、广东省发改委主任李春洪透露"}]}`

### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
releaseTime         | 发布时间
longitude           | 经度
latitude            | 纬度
collectid           | 新闻编号
typeName            | 类型名
link                | 链接
title               | 主题
createTime          | 创建时间
tokenCode           | 开机时间
bizid               | 微博返回id
sourceID            | 源编号
description         | 新闻描述


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign not match            | 请阅读语镜公司提供的签名算法
ME18040     | argument error            | 请检查输入参数

### 测试地址: api.daoke.io/fetchCollectionNews


