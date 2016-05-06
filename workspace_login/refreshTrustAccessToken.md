### 刷新令牌  
* 接口地址： https://rtr.daoke.me/refreshTrustAccesstoken
* 支持格式： Json
* 请求方式： https POST
* 接口备注：
* 调用样例及调试工具：
* 请求参数说明：

| 参数名    | 类型    | 是否必传 | 说明                        |
| :--------| :------ | :-------| :--------------------------|
|  appkey   | string  |  Y     |   开发者账号 开发者的唯一key         |
|  sign     | string  |   Y    |  签名 用secrect通过sha2对请求参数加密结果  |
|  refreshtoken | string  |  Y   |  更新接口调用凭证          |             

* 请求示例：

head头信息：
```
POST /refreshTrustAccesstoken HTTP/1.0
Host:127.0.0.1:80
Content-Length:118
Content-Type:application/json

appkey:bcYtC65Gc89
sign:45456asdfserwerwefasdfsdf
refreshtoken:sdfsdfsdf23423423

```


* 返回参数说明            

| 参数名     | 类型      |  说明                        |        
| :---------| :------- | :----------------------------|       
| accountID | string     |  道客唯一编号 accountID   |      
| accessToken | int     |  网页授权接口调用凭证   |     
| accessTokenExpiration   | string  | Y    |      
| refreshToken   |  string    |  Y   |        
| refreshTokenExpiration   |  string    |  Y   |        


#### 失败示例
```
{
    "ERRORCODE":"ME01002",
    "RESULT":"appKey error"
}
```    

```
{
    "ERRORCODE":"ME18073",
    "RESULT":"Refresh Token expire!"
}
```

#### 成功示例
```
{
  "ERRORCODE":"0",
  "RESULT":{
        "accountID":"hybj68Vbv9",
        "accessTokenExpiration":"434324adfdfdfsdfsdfsd",
        "refreshToken":"sdfsdfsdf23423423",
        "accessToken":"sfg234234234234",
        "refreshTokenExpiration":"20160322120000"
        }
  }
```
