向用户邮箱发送验证URL地址的API
=================================

### API编号

### 功能简介
* 向用户的邮箱发送一封邮件以验证该邮箱

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明                 |  类型       |   示例             |是否允许为空|  限制条件
------------------------|-------------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识                | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名                | string      |  无                |否          | 长度为40
 userEmail              | 用户邮箱                | string      |  无                |否          | 合法的邮箱地址
 URL                    | 用户验证邮箱的URL地址   | string      |  无                |否          | 回调跳转的地址
 content                | 验证邮箱时的额外展示内容| string      |  无                |否          | 需进行URL编码


### 示例代码

    POST /accountapi/v2/sendVerificationURL HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:141
    Content-Type:application/x-www-form-urlencoded

    content=hellonihao&URL=https://github.com/jayzh1010&sign=52550C6CD0195C0E3D7023D065A76E99C3174437&userEmail=56025576@qq.com&appKey=1111111111

 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok!"}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
无              | 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数


### 测试地址: api.daoke.io/accountapi/v2/sendVerificationURL
