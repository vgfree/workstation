
### 3.1.2 修改频道信息
* 接口地址: `https://rtr.daoke.me/channelapi/modifyChannel`
* 支持格式: Json
* 请求方式: https POST
* 接口备注：修改用户频道或主播频道信息
* 调用样例及调试工具
* 请求参数说明:

> 参数         | 参数说明    | 类型       |   示例      | 是否必传 | 限制条件
>--------------|-------------|------------|-------------|--------------|----------------
 appKey         | 应用标识    | string   | 3055426974    | Y           | 长度不大于10
 sign         | 安全签名      | string     | 无         | Y           | 长度为40
 accountID    | 语镜用户帐户编号 | string  | e8O1W0ytqy | Y           | 长度为10的字母
 tokenCode     | 令牌访问权限  |string     |1472583690 | Y          | 无
 timestamp     | 时间戳        |string     |1463708082 | Y          | 无
 chID        | 频道编号      | String    | 00000755  | Y          |
 chName   | 频道名称      | string    | 无       | Y           | 长度大于2 最大长度16，可以是汉字
 chIntro | 频道简介   | string  | 无    | Y           | 长度大于1 最大长度128，可以是汉字
 aIntro | 频道创建者介绍   | string  | 无    | N           | 长度大于1 最大长度128，可以是汉字
 chLogo   | 频道chLogo地址  | string | 无| N | 最大长度128，必须图片格式结尾
 keyWords  |频道关键字   |string |aaa,bbb,ccc |N |单个关键字标签最长是8，关键词最多由5个关>键字标签组成


* 请求示例
head头信息:

```
POST /channelapi/modifyChannel  HTTP/1.0
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
    "chID":"00000755",
    "chName":"一路有你",
    "chIntro":"道路交流",
    "aIntro":"我是牛人",
    "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg",
    "keyWords":"交流"
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
    "ERRORCODE": "ME01002",
    "RESULT": "appKey error"
}
```
>成功示例
>
```
{
    "ERRORCODE": "0",
    "RESULT": "ok!"
}
```
