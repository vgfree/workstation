批量获取WEME++键功能
========================

### API编号
* 

### 功能简介
* 批量获取WEME++键功能

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数           |参数说明                                                   |  类型     |   示例     | 是否允许为空 |  限制条件
----------------|-----------------------------------------------------------|-----------|------------|--------------|--------------
 appKey         | 应用标识                                                  | string    | 1111111111 |  否          | 长度不大于10
 sign           | 安全签名                                                  | string    | 无         |  否          | 长度为40
 accountIDs      | 语镜用户帐户编号                                          | string    | aaaaaaaaaa |  否          | 长度为10的字母
 count     	|用户数量						    | number 	|1	      |否	    |无


### 示例代码/clientcustom/v2/batchFetchUserKeyInfo


POST /clientcustom/v2/batchFetchUserKeyInfo HTTP/1.0
Host:api.daoke.io:80
Content-Length:655
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryDcO1SS14224460020457550MTDfpuu1422446002kkU

------WebKitFormBoundaryDcO1SS14224460020457550MTDfpuu1422446002kkU
Content-Disposition: form-data; name="sign"

FD9E5086526CF235A02C8D202C622C84153DFD0B
------WebKitFormBoundaryDcO1SS14224460020457550MTDfpuu1422446002kkU
Content-Disposition: form-data; name="accountIDs"

bbbbbbbbbb,aaaaaaaaaa
------WebKitFormBoundaryDcO1SS14224460020457550MTDfpuu1422446002kkU
Content-Disposition: form-data; name="count"

2
------WebKitFormBoundaryDcO1SS14224460020457550MTDfpuu1422446002kkU
Content-Disposition: form-data; name="appKey"

1111111111
------WebKitFormBoundaryDcO1SS14224460020457550MTDfpuu1422446002kkU--

### 返回body示例
* 成功: `{"ERRORCODE":"0", "RESULT":{"count":"3","list":[{"{"customParameter":"10086","accountID":"aaaaaaaaaa","customType":"2"},{"customParameter":"c222222","accountID":"bbbbbbbbbb","customType":"2"}]}}`

* 失败: `{RORCODE":"ME01002", "RESULT":"appKey error"}`


### 错误编码

 参数                 | 错误描述               | 解决办法
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数


### 测试地址: api.daoke.io/clientcustom/v2/batchFetchUserKeyInfo


