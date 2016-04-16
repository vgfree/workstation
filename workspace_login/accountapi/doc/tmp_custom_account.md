批量创建用户账号的API
===============================

### API编号

### 功能简介
* 批量创建用户账号

### 说明
* 这个API与addcustomaccount API类似，只是根据条件对addcustomaccount进行了循环，而且只对公司内部使用。

### 输入参数

这个API的输入参数全部需要写进程序里面，config_for_test.lua文件中的body输入为空即可。下面是需要写进程序里面的参数
	appKey  username  daokePassword  nickname  tradeNumber(订单号)

### 运行
	与普通API相同

### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功: `{"ERRORCODE":"0", "RESULT":"ok!"}`

### 返回结果参数

参数                    | 参数说明
------------------------|--------------------------------
无						| 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME01002     | username已经存在          | 请选择未注册的用户名

### 测试地址: api.daoke.io/accountapi/v2/tmpCustomAccount 
