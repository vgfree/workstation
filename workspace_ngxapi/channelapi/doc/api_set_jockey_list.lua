## 3.2 主播频道接口

### 3.2.1 设置主播频道的主持人名单
* 接口地址: `https://rtr.daoke.me/channelapi/setJockeyList`
* 支持格式: Json
* 请求方式: https POST
* 接口备注
* 调用样例及调试工具
* 请求参数说明:

>参数          | 参数说明    | 类型       |   示例      | 是否必传 | 限制条件
>------------ |-------------|------------|-------------|--------------|----------------
 appKey       | 应用标识    | String   | 3055426974    | Y           | 长度不大于10
 sign         | 安全签名      | String     | 无         | Y           | 长度为40
 accountID    | 语镜用户帐户编号 | String  | e8O1W0ytqy | Y           | 长度为10的字母
 tokenCode    | 令牌访问权限  |String     |1472583690 | Y          | 无
 timestamp    | 时间戳       |  String   |1458266656 | Y          |  无
 chID     | 频道编号     | String  | FM00090080    | Y           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母
 jockeyList     | 主持人名单     | []  |  无           | Y           | 主持人accountID数组


* 请求示例
head头信息:

```
POST /channelapi/setJockeyList  HTTP/1.0
Host:rtr.daoke.me
Content-Length:312
Content-Type:application/json

appKey:3055426974
tokenCode:1472583690
sign:2E3B6B488CD75214BDBDD6BCBAC5D494DE21D8D3
accountID:e8O1W0ytqy
timestamp:1458266656
```

body体:
```
{
    "chID"="10001",
    "jockeyList"=[
      "e8O1W0ytqy",
      "f9O1W0ytqy"
    ]
}

```

* 返回参数说明

参数名    |	类型	| 说明
----------|---------|---------------------------------------
ERRORCODE |String	|请求结果标识 0：成功 不为0:操作失败
RESULT	  |String	|请求结果,当errcode=0时，返回修改成功；当errcode不等于0时，返回的是错误原因

* JSON返回示例

> 失败示例
>
```
{
    "ERRORCODE":"ME01002",
    "RESULT":"appKey error"
}
```
>成功示例
>
```
{
    "ERRORCODE": "0",
    "RESULT": "ok"
}
```
