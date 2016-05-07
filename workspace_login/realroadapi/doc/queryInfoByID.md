实景路况修改个人资料API
======================

### API 编号

### 功能简介
*  修改个人资料详情。

### 接口地址
*  https:/rtr.daoke.me/club/accountInfo/queryInfoByID

### 支持格式
* Json

### 请求方式
* https POST

### 接口备注

### 请求参数
| 参数名         | 类型     | 说明
| :-------------| :------- | :--------------------------
| accessToken           | String    | 网页授权接口调用凭证
| accountID             | String   | 道客唯一编号 accountID
| accessTokenExpiration | String   |  接口调用凭证有效期
| refreshToken          | String    |  更新接口调用凭证
| refreshTokenExpiration| String    | 更新接口调用凭证有效期

### 请求示例
head头信息:
```
POST /accountInfo/queryInfoByID HTTP/1.0
Host:127.0.0.1:80
Content-Length:118
Content-Type:application/json

appkey:bcYtC65Gc89
accountid:PdL1eoEl7P
accesstoken:1472583690
timestamp:1458266656
sign：1545678adsfaf234234234wf
```

### 返回参数说明
| 参数名          | 类型     | 说明
| :------------- | :------- | :-----------------------------
|ERRORCODE	     | String	  | 请求结果标识 0：成功 1:操作失败
|RESULT	         | String	  |请求结果 当errcode=0时，返回修改成功；当errcode为错误编码时，返回的是错误原因
|nickName	      | String	 | 用户昵称
|headPic	      | String	 | 头像路径
|birthday	      | String	 | 生日 格式 yyyy-MM-dd
|sex	          | int	     | 性别 0：女；1：男； 2：未知
|cityName	      | String	 | 城市名称
|cityCode	      | String	 | 城市编号
|introduction	  | String	 | 心情 最大字符数：64
|carBrand	      | String	 | 我的爱车 车品牌
|carModel	      | String	 | 我的爱车 车型号
|carNumber	    | String	 | 车牌号码

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
    "ERRORCODE": "0",
    "RESULT": {
        "nickName": "科比-布莱恩特",
        "headPic": "http:// clubapp.daoke.me/club/resource/head_big.png",
        "birthday":"1990-11-21",
        "sex":1,
        "cityName":"上海",
        "cityCode":"310000"
        "introduction":"我为车狂"
        "carBrand":"宝骏"
        "carModel":"730"
        "carNumber":"豫G 88888"
    }
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
* http://192.168.1.207/club/accountInfo/queryInfoByID
