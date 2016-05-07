实景路况修改个人资料API
======================

### API 编号

### 功能简介
*  修改个人资料详情。

### 接口地址
*  https://rtr.daoke.me/dfsapi/v2/saveImage

### 支持格式
*  multipart/form-data

### 请求方式
* https POST

### 接口备注
* 表单格式

### 请求参数
| 参数名         | 类型     | 说明
| :-------------| :------- | :--------------------------
|appKey	        | String	 | 开发者KEY
|sign	          | String	 | 签名
|length	        | double	 | 图片大小
|isStorage	    | String	 | 是否存储到dfsdb(true false):不传或为空则默认false,表示存储到redis
|cacheTime	    | double	 | 缓存时间:秒 不传或为空表示dfsdb或redis不过期
|image实体	    | bit	      |

### 请求示例
head头信息:
```
POST /club/accountInfo/updateInfoByID
Host:127.0.0.1:80
Content-Length:118
Content-Type:application/json

appkey:bcYtC65Gc89
sign：1545678adsfaf234234234wf
```

body体:
```
------WebKitFormBoundarymiA5o7JWrgF9Klcq
Content-Disposition: form-data; name="length"
1050
------WebKitFormBoundarymiA5o7JWrgF9Klcq
Content-Disposition: form-data; name="mmfile"; filename="1.jpg"
Content-Type: image/jpeg
二进制文件内容
------WebKitFormBoundarymiA5o7JWrgF9Klcq--
```
### 返回参数说明
| 参数名          | 类型     | 说明
| :------------- | :------- | :-----------------------------
|ERRORCODE	     | String	  | 请求结果标识 0：成功 1:操作失败
|RESULT	         | String	  |请求结果 当errcode=0时，返回修改成功；当errcode为错误编码时，返回的是错误原因
| url            | String   | 图片url
| fileID         | String   | 文件标识
| fileSize       | string   | 文件大小
### 返回示例
失败示例
```
{
    "ERRORCODE":"ME01002",
    "RESULT":"appKey error"
}
```

成功示例
```
{
"ERRORCODE":"0",         
"RESULT":
{
    "url":"http://v1.mmfile.daoke.me/group1/M00/00/13/rBALdFM9BXiAKcAUAAW5LIgSrzk132.jpg",
    "fileID":"b64f7158da8b11e3ae3b000c29b90439",
    "fileSize":"143305"
}
```
### 错误编码
| 错误编码        | 错误描述               | 解决办法
| :------------- | :-------------------- | :----------------------------
| ME01002        | appKey error          | appKey需使用从语镜公司申请得到的appKey
| ME18015        | this accountID has no finance information! | 检查accounID
| ME01006        | error json data!      | 参数错误
| ME01023        | %s is error!          | 请检查参数
| ME01020        | mysql failed!         | 检查mysql连接

### 测试接口  
* http://192.168.71.84:2223/dfsapi/v2/saveImage
