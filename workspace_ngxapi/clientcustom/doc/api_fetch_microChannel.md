微频道列表
========================

### API编号
* 

### 功能简介

1.获取所有待审核的微频道

2.获取微频道所有者的微频道

3.查询所有能关注的微频道


### 参数格式

* API以 **POST** 方式请求，使用表单FORM方式提交

### 输入参数

 参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|--------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 语镜用户帐户编号   | string  | 2222222222    | 否           | 长度为10的字母
 channelNumber              | 频道编号           | string  | FM00090080    | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母
 channelStatus              | 频道状态           | int     | 1     		   | 否           | 频道状态
 infoType                   | 函数接口           | int     | 1 			   | 否           | 信息标志 
 startPage                  | 起始索引           | int     | 1     		   | 是           | 正整数
 pageCount                  | 每页显示条数       | int     | 1     		   | 是           | 小于500的正整数
 cityCode                   | 频道区域编码       | int     | 100000     	   | 是           | 正整数 ,长度6位到10位		
 channelName                | 频道名称           | string  | abcdef    	   | 是           | 长度大于2,最大长度16,可是汉字					
 catalogID                  | 频道类别编号       | int     | 100000     	   | 是           | 正整数 ,长度6位到10位
 channelKeyWords            | 频道关键词         | string  | aa,bb,cc         |是            | 单个关键字标签最长是8，关键词最多由5个关键字标签组成
 sortField                  | 排序字段           | string  | a,d,c            | 是           | 返回结果排序依据(倒序),popularity受欢迎度/userCount/用户总人数,number/频道编码,name/频道名称,cityCode/城市编码
 accessToken                | 令牌访问权限       |string   |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否              |长度为32

### 特别说明	

infoType   | 调用身份  | channelStatus           |  功能说明            |   tableType             |   checkStatus
-----------|------------|----------------------|-----------------------|-------------------------|------------------
     0     | 公司内部  |  0                     |   未审核             |    1                    |     0  待审核
     0     | 公司内部  |  1                     |   驳回               |    1                    |     1  驳回
     0     | 公司内部  |  2                     |   审核成功           |    1                    |     2.审核成功 4.关闭
     0     | 公司内部  |  10                    |   所有               |    1                    |     0/1/2/4 所有结果
     1     | 频道管理员  |  1                   |   返回申请表结果集   |    1                    |    0  待审核  1 驳回 (不包含审核成功数据) 
     1     | 频道管理员  |  2                   |   审核成功的数据     |    2                    |    1  正常    2 正在修改
     1     | 频道管理员  |  3                   |   修改已审核频道数据 |    3                    |    2  修改后等待审核, 3关闭
     1     | 频道管理员  |  空(不传)            |   返回管理员所有数据 |    1/2/3                |   0/1/2 所有可能
     2     | 普通用户    |  空(不传)            |   返回所有能关注的数据 |    3                  |   1  正常 


### 示例代码/clientcustom/v2/fetchMicroChannel 

     POST /clientcustom/v2/fetchMicroChannel HTTP/1.0
     Host:api.daoke.io:80
     Content-Length:741
     Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU

     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU
     Content-Disposition: form-data; name="channelStatus"

     1
     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU
     Content-Disposition: form-data; name="accountID"

     2222222222
     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU
     Content-Disposition: form-data; name="sign"

     4B25A581B8DCC3D23A2CF4B9C979E1D121CB324D
     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU
     Content-Disposition: form-data; name="infoType"

     2
     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU
     Content-Disposition: form-data; name="appKey"

     2222222222
     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU
     Content-Disposition: form-data; name="accessToken"


     aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
     ------WebKitFormBoundaryDcO1SS14157044532625920MTDfpuu1415704453kkU--

### 返回body示例

* 成功:

#####infoType = 0,channelStatus = 0.1.2.10
          1.`{"ERRORCODE":"0", "RESULT":{"count":"1","list":{"number":"FM090909","accountID":"2222222222","catalogName":"","createTime":"1415696887","checkStatus":"0","chiefAnnouncerIntr":"主播是必填的","name":"WANGNIMA","introduction":"频道简介"}}}`
     		
#####infoType = 1
          2.`{"ERRORCODE":"0", "RESULT":{"count":"1","list":{"number":"FM090909","accountID":"2222222222","catalogName":"","createTime":"1415696887","checkStatus":"0","chiefAnnouncerIntr":"主播是必填的","name":"WANGNIMA","introduction":"频道简介"}}}`

#####infoType = 2		
          3.`{"ERRORCODE":"0", "RESULT":{"count":"1","list":{"userCount":"6723","cityCode":"310000","inviteUniqueCode":"wemeVOICE|fa5634fea6da11e4a9d700a0d1e9d528","introduction":"微密官方频道 及时路况信息发布 爱车宝典 吃喝玩乐!美女帅哥主播带你happy带你飞!","checkStatus":"1","cityName":"上海市","chiefAnnouncerName":"屌炸天的基友","catalogName":"交通出行","accountID":"kxl1QuHKCD","name":"微密之声","logoURL":"http:\/\/g4.tweet.daoke.me\/group4\/M0E\/FD\/C4\/c-dJUFT2dxmAZytHAAFDc8PYqVQ620.png","chiefAnnouncerIntr":"微密一大波帅哥美女主播正在靠近你!","catalogID":"100109","number":"wemeVOICE"}}}`
     		
#####没有查询到信息		
          4.`{"ERRORCODE":"0", "RESULT":{"count":"0","list":[]}}`
     		
* 失败: 
          `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数           | 参数说明
---------------|--------------------------------
count          |数字 ,记录集
list           |二维数组,查询返回信息集合
number         |微频道频道号
catalogName    |类别名称
createTime     |创建时间
checkStatus    |审核状态
chiefAnnouncerIntr |主播简介
name           |频道名称
introduction   |频道简介
logoURL        |微频道LOGO
inviteUniqueCode |微频道邀请码
chiefAnnouncerName |主播名


### 错误编码

 参数                 | 错误描述                        | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | ok                             | 正常调用
 ME01003              | access token not matched            | 令牌访问权限不匹配
 ME01002              | appKey error                   | appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!                  | 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match              | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!           | 系统错误，请与公司客服联系
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参

 
### 测试地址: api.daoke.io/clientcustom/v2/fetchMicroChannel

