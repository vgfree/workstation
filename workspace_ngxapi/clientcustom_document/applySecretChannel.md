打印 debug----Exec sql update userAdminInfo set `create` = `create` + 1 ,updateTime = 1459157850 where accountID = 'qkc1C2agiC'


insert into checkSecretChannelInfo(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, logoURL,openType,capacity,accountID,createTime,inviteUniqueCode,isVerify,keyWords,channelNameURL,userCount) values ('000007741','000007741', 'louis0', 'friends', 110000, '北京市', 301020, '两性情感',  '' , 0, 1000, 'qkc1C2agiC', 1459157850,'000007741|b4b083d6f4c811e5873e000c29ae7997',0 ,'','',1)


insert into checkSecretChannelInfoHistory(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, logoURL,openType,capacity,updateTime,channelStatus,appKey,isVerify,accountID,inviteUniqueCode,keyWords,channelNameURL)select idx,number,name,introduction,cityCode,cityName,catalogID,catalogName,logoURL,openType,capacity,'1459157850', channelStatus,'2064302565',isVerify , accountID,inviteUniqueCode,keyWords,channelNameURL  from checkSecretChannelInfo where accountID = 'qkc1C2agiC' and cityCode = 110000 and catalogID = 301020 and isVerify = 0


insert into userChannelList(idx,number,accountID,channelType,createTime) values ('000007741','000007741','qkc1C2agiC',2,1459157850)


insert into joinMemberList(idx , number, uniqueCode , accountID, createTime,role)  values('000007741','000007741','000007741|b4b083d6f4c811e5873e000c29ae7997','qkc1C2agiC',1459157850,1)


insert into joinMemberListHistory(idx,number,accountID,uniqueCode, updateTime,role)  select idx, number, accountID,uniqueCode,createTime,role from joinMemberList where accountID = 'qkc1C2agiC' and number = '000007741'  



## MySQL
> channel_dbname : app_custom___wemecustom

## applySecretChannel 运行流程  
