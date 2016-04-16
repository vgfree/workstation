根据第三方账户创建语镜帐号
========================

### API编号
* S0102V2

### 功能简介
* 根据第三方的账户（如微信等）创建语镜帐号

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                 |参数说明                  |  类型       |   示例      | 是否允许为空      |  限制条件
----------------------|--------------------------|-------------|-------------|-------------------|--------------
 appKey               | 应用标识                 | string      | 1111111111 |  否                | 长度不大于10
 sign                 | 安全签名                 | string      | 无         |  否                | 长度为40
 account              | 第三方帐户               | string      | adfdsfasdf |  否                | 长度为小于64
 loginType            | 帐户类型:5微信,7凯立德   | string      | 7          |  否                | 
 nickname             | 昵称                     | string      | hello      |  否                |

### 代码示例

    POST /accountapi/v2/generateDaokeAccount HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:108
    Content-Type:application/x-www-form-urlencoded
    
    appKey=184269830&account=1418052377&loginType=7&sign=1E9826B65D1549DA1979976FAAE272A983600197&nickname=asdf


### 返回body示例
 
* 成功:       "ERRORCODE": "0", 
    "RESULT": {
        "isNew": 1, 
        "isHasDaokeAccount": 0, 
        "lastLoginTime": "", 
        "accountID": "nw000V6wk5", 
        "nickname": "asdf", 
        "registerTime": "1429502094"
    }
}

* 失败:    {"ERRORCODE":"ME01002", "RESULT":"appKey error"}

### 返回结果参数

 参数                 | 参数说明 
----------------------|----------------------
 isNew                | 是否为新注册账号 
 isHasDaokeAccount    | 是否有道客账户 
 lastLoginTime        | 上次登录时间
 registerTime         | 注册时间
 nickname             | 昵称
 accountID            | 账户编号
### 错误编码

 参数                 | 错误描述               | 解决办法
----------------------|------------------------|------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01006              |error json data!         |请与公司客服联系
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01020              |mysql failed!        |请与公司客服联系
 ME01021              |redis failed!        |请与公司客服联系
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME01025              |http failed!         |请与公司客服联系
 ME01026              |system is busy now   |请与公司客服联系
 ME18001              |错误                |请检查输入参数


### 测试地址: api.daoke.io/accountapi/v2/generateDaokeAccount
