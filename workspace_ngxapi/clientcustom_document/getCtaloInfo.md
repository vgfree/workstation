## MySQL
> channel_dbname : app_custom___wemecustom
**Tables_in_WEMECustom**    
+---------------------------------------+
| Tables_in_WEMECustom                  |
+---------------------------------------+
| WEMEKeyInfo                           |
| applyMicroChannelInfo                 |
| applyMicroChannelInfoHistory          |
| applyMicroChannelInfoHistory_20150527 |
| applyMicroChannelInfo_20150527        |
| applyServiceChannelInfo               |
| applyServiceChannelInfo_bak           |
| applyServiceChannelInfo_bak_20150729  |
| channelCatalog                        |
| channelCatalog_20150527               |
| channelCatalog_copy                   |
| checkMicroChannelInfo                 |
| checkMicroChannelInfo_20150527        |
| checkSecretChannelInfo                |
| checkSecretChannelInfoHistory         |
| checkServiceChannelInfo               |
| checkServiceChannelInfo_bak_20150729  |
| deviceInitChannel                     |
| deviceInitChannelHistory              |
| followUserList                        |
| followUserListHistory                 |
| groupInfo                             |
| inviteLinksHistory                    |
| joinMemberList                        |
| joinMemberListHistory                 |
| joinMemberListView                    |
| modifyMicroChannelInfo                |
| modifyMicroChannelInfo_20150527       |
| modifyServiceChannelInfo              |
| modifyServiceChannelInfo_bak_20150729 |
| serviceChannelContentInfo             |
| testTable                             |
| transferInfo                          |
| userAdminInfo                         |
| userChannelList                       |
| userChannelList_20150527              |
| userCustomDefineInfo                  |
| userGroupHistory                      |
| userGroupInfo                         |
| userKeyHistory                        |
| userKeyInfo                           |
| userKeyInfo_20150527                  |
| userShutUpInfo                        |
| userVerifyMsgInfo                     |
| userVoiceNotepad                      |
+---------------------------------------+

**show full columns from channelCatalog**
+--------------+---------------------+-----------+------+-----+---------+-------+----------------------+--------------------------------------------------------------------------+
| Field        | Type                | Collation | Null | Key | Default | Extra | Privileges           | Comment                                                                  |
+--------------+---------------------+-----------+------+-----+---------+-------+----------------------+--------------------------------------------------------------------------+
| id           | int(10) unsigned    | NULL      | NO   | PRI | 0       |       | select,insert,update | 频道类型编号                                                       |
| name         | varchar(32)         | utf8_bin  | NO   |     |         |       | select,insert,update | 频道类型名称                                                       |
| introduction | varchar(32)         | utf8_bin  | NO   |     |         |       | select,insert,update | 频道类型简介                                                       |
| catalogType  | tinyint(4) unsigned | NULL      | NO   |     | 0       |       | select,insert,update | 类别适用场景 0公共类别  1微频道类别  2群聊频道类别  |
| validity     | tinyint(4) unsigned | NULL      | NO   |     | 1       |       | select,insert,update | 是否有效  1有效  0无效                                           |
| sortIndex    | int(10) unsigned    | NULL      | NO   |     | 0       |       | select,insert,update | 用户排序                                                             |
| logoURL      | varchar(128)        | utf8_bin  | NO   |     |         |       | select,insert,update | 频道分类logoUrl                                                      |
| createTime   | int(10)             | NULL      | NO   |     | 0       |       | select,insert,update | 申请时间                                                             |
| updateTime   | int(10)             | NULL      | NO   |     | 0       |       | select,insert,update | 更新时间                                                             |
+--------------+---------------------+-----------+------+-----+---------+-------+----------------------+--------------------------------------------------------------------------+
