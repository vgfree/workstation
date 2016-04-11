
用户加入/退出临时频道
========================

### API编号
* 

### 功能简介
* 用户加入/退出临时频道

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                                 | 参数说明           | 类型      |   示例             | 是否允许为空 | 限制条件
--------------------------------------|---------------------|------------|--------------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无                 | 否           | 长度为40
 accountID                  | 用户帐号           | string  | 2222222222    | 否           | 长度为10或者15位,帐号必须在线
 tempChannelID              | 临时频道           | string  | 0123520       | 否           | 长度为5~8位的数字(允许0开头),退出临时频道,该参数不传递
 customType                 | 设置参数           | string  | 1/2           | 否           | 1 加入临时频道  2 退出临时频道
 accessToken                | 令牌访问权限        |string   |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |



### 示例代码/clientcustom/v2/setUserTempChannel

    POST /clientcustom/v2/setUserTempChannel HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    customType=1&sign=419B70B309925749CAEF2A33418A02B08E0A7C61&tempChannelID=123456&accountID=2222222222&appKey=1111111111&accessToken=cc7df2350a7755214dc93df48e15d682
    


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":"ok!"}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01004              | accessToken expire     | 访问令牌已过期
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME18005              | 不存在此字段           | 请检查输入参数


### 测试地址: api.daoke.io/clientcustom/v2/setUserTempChannel


