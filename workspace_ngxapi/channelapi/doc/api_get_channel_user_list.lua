

### 3.1.9 获取频道的用户列表

* 接口地址: `https://rtr.daoke.me/channelapi/getChannelUserList`
* 支持格式: Json
* 请求方式: https POST
* 接口备注: 获取频道(普通频道或主播频道)的列表
* 调用样例及调试工具
* 请求参数说明:

>参数              |参数说明         |  类型       |   示例         |是否必传|  限制条件
>------------------|-----------------|-------------|----------------|------------|---------------------
appKey           | 应用标识        | string      |  1111111111    |Y           | 长度不大于10
sign             | 安全签名        | string      |  无            |Y           | 长度为40
accountID        | 账户编号        | string      |  aaaaaaaaaa    |Y           | 长度为10
accessToken      | 令牌访问权限     |string       |aaaaaaaaaaaaaaa | Y          |无
timestamp       | 时间戳        |string     |1463708082 | Y          | 无
chID            | 频道号          | string      |  100101        |Y           | 长度为1到50之间，不能存在"'"


* 请求示例
head头信息:

```
POST /channelapi/getChannelUserList  HTTP/1.0
Host:rtr.daoke.me
Content-Length:312
Content-Type:application/json

appKey:3055426974
tokenCode:1472583690
sign:2E3B6B488CD75214BDBDD6BCBAC5D494DE21D8D3
accountID:e8O1W0ytqy
timestamp:1463708082
```
body体:
```
{
    "chID":"10081"
}
```
* 返回参数说明

参数名    |	类型	| 说明
----------|---------|---------------------------------------
ERRORCODE |String	|请求结果标识 0：成功 不为0:操作失败
RESULT	  |String	|请求结果,当errcode=0时，返回修改成功；当errcode不等于0时，返回的是错误原因
count     |int    | 频道数目
list      |[] | 频道列表
UID      |String | 用户编号
sex      |int | 性别 1:男 2:女 0：未知
uName    | String| 用户名称
uCity    | String| 用户所在城市
uLogo     | String| 用户头像

* JSON返回示例

> 失败示例
>
```
{
    "ERRORCODE": "ME01023",
    "RESULT": "accountID is error!"
}
```
>成功示例
>
```
{
    "ERRORCODE": "0",
    "RESULT": {
        "count": 2,
        "list": [
            {
                "UID": "abcderfadc",
                "sex":1,
                "uName": "人生若只如初见",
                "uCity": "上海",
                "uLogo":"http://esmart.chinajoy.net/Content/Upload/20160413094726_3105.jpg",
            },
            {
                "UID": "abcderfadc",
                "sex":1,
                "uName": "画扇",
                "uCity": "上海",
                "uLogo":"http://esmart.chinajoy.net/Content/Upload/20160413094726_3105.jpg"
            }
        ]
    }
}
```
