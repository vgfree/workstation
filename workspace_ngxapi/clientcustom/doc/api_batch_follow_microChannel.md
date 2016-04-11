批量添加用户到微频道
========================

### API编号

### 参数格式

* API以 **POST** 方式请求，使用key-val方式提交

### 输入参数

 参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 totalList               | 批量的imei或accountID    | string  | 2222222222,111111111111111    | 否           | 逗号作为imei或accountID的分割符

### 示例代码/clientcustom/v2/batchFollowMicroChannel

POST /clientcustom/v2/batchFollowMicroChannel HTTP/1.0
Host:127.0.0.1:80
Content-Length:8060
Content-Type:application/x-www-form-urlencoded


totalList=111111111,abc1234,111111111111111,111111111111111,111111111&uniqueCode=FM456789|068cba469ad711e4b68974d4350c77be&sign=23CF3DD7A4CB4AA540F410E03CC2E4DC8B38F53A&appKey=111111111


### 返回body示例

* 成功:
`{"ERRORCODE":"0", "RESULT":{"total":"5","successed":"1","failed":"4","failedReason":{"imeiNoAccountid":"0","followSelf":"1","repeatFollow":"1","errorParameter":"1","accountIDError":"1"}}}
`
		
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回参数 

返回参数                  	| 参数说明            
--------------------------------|-----------------------------------------------------------------------
successed				| 成功的总条数
total 					| 传入的imei或accountID的总条数
failed 					| 失败的总条数 
failedReason			| 失败的原因
followSelf 				| 关注自己的个数
imeiNoAccountid 			| imei获取不到accountID的个数   
errorParameter			| 错误的参数的个数，既不是imei,也不是accountID的有个数
repeatFollow			| 重复关注的个数
accountIDError			| 错误的accountID的个数
callApiError 			| 调用API失败的个数

### 错误编码

 参数                 | 错误描述              | 解决办法     
----------------------|----------------------|---------------------------------------
 0                    | 调用成功              | 
 ME01002              | appKey error         | appKey需使用从语镜公司申请得到的appKey
 ME01023              | parameter is error!     | 参数错误，请按照文档提供的参数要求传参
 ME01019              | sign is not match       | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!    | 系统错误，请与公司客服联系

 


### 测试地址: api.daoke.io/clientcustom/v2/batchFollowMicroChannel


