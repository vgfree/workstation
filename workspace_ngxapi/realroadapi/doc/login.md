实景路况用户登录API
======================

### API 编号

### 功能简介  
* 我们使用道客账户的oAuth登录注册方式来进行登录注册。

### 接口地址  
*  https://rtr.daoke.me/oauth

### 支持格式  
* Json  

### 请求方式  
* https POST  

### 接口备注  

### 请求参数  
| 参数名                 | 类型     | 是否必传  | 说明                        |
| :-------------------- | :------- | :--------| :--------------------------|
| accessToken           | String   | Y        | 网页授权接口调用凭证          |
| accountID             | String   | Y        | 道客唯一编号 accountID       |
| accessTokenExpiration | String   | Y        |  接口调用凭证有效期           |
| refreshToken          | String   | Y        |  更新接口调用凭证             |
| refreshTokenExpiration| String   | Y        | 更新接口调用凭证有效期        |

### 请求示例  
head头信息:  
```
POST /oauth HTTP/1.0
Host:127.0.0.1:80
Content-Length:118
Content-Type:application/json

accesstoken:sfg234234234234
accountid:hybj68Vbv9
accesstokenexpiration:434324adfdfdfsdfsdfsd
refreshtoken:sdfsdfsdf23423423
refreshtokenexpiration:20160322120000
```
### 返回参数说明
| 参数名          | 类型     | 说明                            |
| :------------- | :------- | :----------------------------- |
| accountID      | string   | 道客唯一编号 accountID           |
| accessToken    | int      | 网页授权接口调用凭证              |

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
  "RESULT":{
    "accessToken": 1472583690,
    "accountID": "PdL1eoEl7P" ,
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

### 测试接口
* http://192.168.1.207/login
