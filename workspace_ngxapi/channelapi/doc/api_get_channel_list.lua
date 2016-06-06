### 3.1.10 获取用户的频道列表
* 接口地址: `https://rtr.daoke.me/channelapi/getChannelList`
* 支持格式: Json
* 请求方式: https POST
* 接口备注: 获取用户的频道(普通频道或主播频道)列表
* 调用样例及调试工具
* 请求参数说明:

>参数              |参数说明         |  类型       |   示例         |是否必传|  限制条件
>------------------|-----------------|-------------|----------------|------------|---------------------
appKey           | 应用标识        | string      |  1111111111    |Y           | 长度不大于10
sign             | 安全签名        | string      |  无            |Y           | 长度为40
accountID        | 账户编号        | string      |  aaaaaaaaaa    |Y           | 长度为10
accessToken      | 令牌访问权限     |string       |aaaaaaaaaaaaaaa | Y          |无
timestamp       | 时间戳          |string     |1463708082 | Y          | 无
UID            | 用户编号          | string      |  100101        |Y           | 长度为1到50之间，不能存在"'"


* 请求示例
head头信息:

```
POST /channelapi/getChannelList  HTTP/1.0
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
    "UID":"10081"
}
```
* 返回参数说明

参数名    |	类型	| 说明
----------|---------|---------------------------------------
ERRORCODE |String	|请求结果标识 0：成功 不为0:操作失败
RESULT	  |String	|请求结果,当errcode=0时，返回修改成功；当errcode不等于0时，返回的是错误原因
count     |int    | 频道数目
list      |string | 频道列表
chID      |String | 频道编号
chName    | String| 频道名称
chIntro     | String| 频道简介
chLogo     | String| 频道Logo
keyWords  | String| 频道关键字

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
                "chID": "0000755",
                "chName": "人生若只如初见",
                "chIntro":"道路交友",
                "chLogo":"http://esmart.chinajoy.net/Content/Upload/20160413094726_3105.jpg"
                "keyWords": "交友"
            },
            {
                "chID": "0000754",
                "chName": "更那堪秋风悲画扇",
                "chIntro":"道路交友",
                "chLogo":"http://esmart.chinajoy.net/Content/Upload/20160413094726_3105.jpg",
                "keyWords": "交友"
            }
        ]
    }
}
```
