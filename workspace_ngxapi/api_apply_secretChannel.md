用户申请群聊频道
========================

### API编号
*

### 功能简介

* 用户申请群聊频道

### 参数格式

* API以 **post** 方式请求，且传送方式为 **key-value键值对**.

### 调用数据库
```lua
app_custom___wemecustom = {
                        host = '192.168.1.6',
                        port = 3306,
                        database = 'WEMECustom',
                        user = 'app_custom',
                        password ='appCu159',
                },
```
### 输入参数

 参数                       	| 参数说明         | 类型    	|   示例      | 是否允许为空 | 限制条件
-----------------------------|-------------------|--------------|-------------|---------------|---------------------------
 appKey            		| 应用标识       	| string  	| 1111111111 	| 否           | 长度不大于10
 sign                       	| 安全签名         	| string  	| 无         	| 否           | 长度为40
 accountID                 	| 语镜用户帐户编号	| string  	| 2222222222 	| 否           | 长度为10的字母
 channelName              	| 频道名称         	| string  	| 无          	| 否           | 长度大于2 最大长度16，可以是汉字
 channelIntroduction     	| 频道简介         	| string  	| 无          	| 否           | 长度大于1 最大长度128，可以是汉字
 channelCityCode         	| 频道区域编号    	| int 		|111111      	| 否           | 长度6-10 ,可为0，数字
 channelCatalogID        	| 频道类别编号    	| int 	  	| 无          	| 否           | 长度6-11，数字
 channelCatalogUrl       	| 频道logourl地址	| string  	| 无         	| 是           | 最大长度128，必须图片格式结尾
 openType                  	|频道开放          	|int      	|1或0        	|否            |1开放 0 非开放
 isVerify     				|是否校验 			|int 	| 1或0			| 是 			| 0 不校验 1 校验
 channelKeyWords 			|频道关键字 			|string |aaa,bbb,ccc	|是 				|单个关键字标签最长是8，关键词最多由5个关键字标签组成
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       | 无


### 示例代码 /clientcustom/v2/applySecretChannel
	POST /clientcustom/v2/applySecretChannel  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:312
	Content-Type:application/x-www-form-urlencoded

	appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa&openType=1&channelCatalogID=111111&channelCatalogUrl=http%3A%2F%2FdJUFV1QwiAQGWxAACj1BEczgI783.jpg&sign=2E3B6B488CD75214BDBDD6BCBAC5D494DE21D8D3&channelCityCode=111111&channelKeyWords=%E9%BA%BB%E9%BA%BB&channelName=%E7%9F%A5%E5%B7%B1&accountID=aaaaaaaaaa&channelIntroduction=%E5%95%A6%E5%95%A6%E5%95%A6&isVerify=0



### 返回body示例

* 成功:`{"ERRORCODE": "0", "RESULT": {"channelNumber": "000000000", "uniqueCode": "000000000|2380b34402c111e58d9f902b34af3648"}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 错误编码

 参数                 	| 错误描述               						| 解决办法     
------------------------|--------------------------------------------------|---------------------------------------
 0                    	| ok              					  		| 正常调用
 ME01002       			| appKey error          					| appKey需使用从语镜公司申请得到的appKey
 ME01003 			  | access token not matched 			| 令牌访问权限不匹配
 ME01023              	| accountid is error!   					| 请与公司客服联系
 ME01019              	| sign is not match     					| 请阅读语镜公司提供的签名算法
 ME01022              	| internal data error!    				| 系统错误,请与公司客服联系
 ME01020              	| mysql failed              				| 数据库错误,请与公司客服联系
 ME01021              	| redis failed!             				| 数据库错误,请与公司客服联系
 ME01023              	| args is error!            			| 参数错误，请检查参数
 ME18104              	| current user channel already exist		| 当前的频道已经存在,请重新申请
 ME18106              	| user channel Maximum         			| 当前用户的密频道已经达到最大值
 ME18109              	| channel number is error      			| 当前频道编码错误,请检查频道编码




### 测试地址: api.daoke.io/clientcustom/v2/applySecretChannel     


apply_user_secret_channel()执行流程     

2016-03-29 14:24:19 [WARN](applySecretChannel)--> channel_name:群聊频道sakura_sakura  txt2voice failed !
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->群聊频道转语音 channelNameURL:, ok_status:false
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->获取频道城市名称 channel_citycode : 110000, channel_cityname : 北京市
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->获取频道列表名称 channel_catalogname is 两性情感
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->获取频道数 channel_num = 000007749
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->获取uniquecode uniquecode = 000007749|e27c2316f57611e5890b000c29ae7997
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->设置频道类型 channelType = 2
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->debug----Exec sql
 update userAdminInfo set `create` = `create` + 1 ,updateTime = 1459232659 where accountID = '32cruxool7'

insert into checkSecretChannelInfo(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, logoURL,openType,capacity,accountID,createTime,inviteUniqueCode,isVerify,keyWords,channelNameURL,userCount) values ('000007749','000007749', 'sakura_sakura', 'just_for_test', 110000, '北京市', 301020, '两性情感',  '' , 0, 1000, '32cruxool7', 1459232659,'000007749|e27c2316f57611e5890b000c29ae7997',0 ,'test','',1)

insert into checkSecretChannelInfoHistory(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, logoURL,openType,capacity,updateTime,channelStatus,appKey,isVerify,accountID,inviteUniqueCode,keyWords,channelNameURL)select idx,number,name,introduction,cityCode,cityName,catalogID,catalogName,logoURL,openType,capacity,'1459232659', channelStatus,'2064302565',isVerify , accountID,inviteUniqueCode,keyWords,channelNameURL  from checkSecretChannelInfo where accountID = '32cruxool7' and cityCode = 110000 and catalogID = 301020 and isVerify = 0

insert into userChannelList(idx,number,accountID,channelType,createTime) values ('000007749','000007749','32cruxool7',2,1459232659)

insert into joinMemberList(idx , number, uniqueCode , accountID, createTime,role)  values('000007749','000007749','000007749|e27c2316f57611e5890b000c29ae7997','32cruxool7',1459232659,1)

insert introductiony(idx,number,accountID,uniqueCode, updateTime,role)  select idx, number, accountID,uniqueCode,createTime,role from joinMemberList where accountID = '32cruxool7' and number = '000007749'  
2016-03-29 14:24:19 [WARN](applySecretChannel)-->channel_num:000007749 channel_idx:000007749  owner:32cruxool7  cur_time:1459232659  capacity:1000
 channel_type:2 open_type:0 , citycode 110000 ,cityname 北京市 ,catalogid 301020,  catalogname 两性情感,channelname sakura_sakura ,introduction just_for_test ,channelname_url :
2016-03-29 14:24:19 [DEBUG](applySecretChannel)-->返回值 channel_num = 000007749, uniquecode = 000007749|e27c2316f57611e5890b000c29ae7997



*****************************************************
加入申请表中
`insert into checkSecretChannelInfo(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, logoURL,openType,capacity,accountID,createTime,inviteUniqueCode,isVerify,keyWords,channelNameURL,userCount) values ('000007749','000007749', 'sakura_sakura', 'just_for_test', 110000, '北京市', 301020, '两性情感',  '' , 0, 1000, '32cruxool7', 1459232659,'000007749|e27c2316f57611e5890b000c29ae7997',0 ,'test','',1)`

```
              id: 6828
             idx: 000007749
          number: 000007749
            name: sakura_sakura
    introduction: just_for_test
        cityCode: 110000
        cityName: 北京市
       catalogID: 301020
     catalogName: 两性情感
         logoURL:
       accountID: 32cruxool7
inviteUniqueCode: 000007749|e27c2316f57611e5890b000c29ae7997
        openType: 0
        capacity: 1000
      createTime: 1459232659
      updateTime: 0
   channelStatus: 1
          remark:
        isVerify: 0
        keyWords: test
  channelNameURL:
     channelType: 0
       userCount: 1
```
************************************************************************************
加入申请表历史      
`insert into checkSecretChannelInfoHistory(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, logoURL,openType,capacity,updateTime,channelStatus,appKey,isVerify,accountID,inviteUniqueCode,keyWords,channelNameURL)select idx,number,name,introduction,cityCode,cityName,catalogID,catalogName,logoURL,openType,capacity,'1459232659', channelStatus,'2064302565',isVerify , accountID,inviteUniqueCode,keyWords,channelNameURL  from checkSecretChannelInfo where accountID = '32cruxool7' and cityCode = 110000 and catalogID = 301020 and isVerify = 0`

```
             id: 1757
            idx: 000007749
         number: 000007749
           name: sakura_sakura
   introduction: just_for_test
       cityCode: 110000
       cityName: 北京市
      catalogID: 301020
    catalogName: 两性情感
        logoURL:
      accountID: 32cruxool7
inviteUniqueCode: 000007749|e27c2316f57611e5890b000c29ae7997
       openType: 0
       capacity: 1000
     updateTime: 1459232659
  channelStatus: 1
         appKey: 2064302565
         remark:
```
************************************************************************************    
`insert into userChannelList(idx,number,accountID,channelType,createTime) values ('000007749','000007749','32cruxool7',2,1459232659)`   
```
id: 7749
           idx: 000007749
        number: 000007749
     accountID: 32cruxool7
checkAccountID:
   channelType: 2
    createTime: 1459232659
```
***********************************************************************************
`insert into joinMemberList(idx , number, uniqueCode , accountID, createTime,role)  values('000007749','000007749','000007749|e27c2316f57611e5890b000c29ae7997','32cruxool7',1459232659,1)`
```
              id: 102636
             idx: 000007749
          number: 000007749
       accountID: 32cruxool7
      uniqueCode: 000007749|e27c2316f57611e5890b000c29ae7997
      createTime: 1459232659
      updateTime: 0
        validity: 1
      talkStatus: 1
            role: 1
      actionType: 0
isNeedVerifyFlag: 0
```
***********************************************************************************
`insert into joinMemberListHistory(idx,number,accountID,uniqueCode, updateTime,role)  select idx, number, accountID,uniqueCode,createTime,role from joinMemberList where accountID = '32cruxool7' and number = '000007749'  `   
```
        id: 10776
       idx: 000007749
    number: 000007749
 accountID: 32cruxool7
uniqueCode: 000007749|e27c2316f57611e5890b000c29ae7997
updateTime: 1459232659
  validity: 1
talkStatus: 1
actionType: 0
      role: 1n
```
*************************************************************************************
