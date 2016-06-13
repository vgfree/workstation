```sql
CREATE TABLE `tbl_channelInfo` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `channelType` tinyint(4) unsigned NOT NULL DEFAULT '0' COMMENT '频道类型 1：用户频道， 2：主播频道',
  `channelID` varchar(20) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '频道编号',
  `channelName` varchar(20) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '频道名称',
  `introduction` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '频道简介',
  `logoURL` varchar(128) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '频道logo url地址',
  `admin` varchar(10) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '申请人,账户ID',
  `capacity` int(10) unsigned NOT NULL DEFAULT '1000' COMMENT '频道容量 默认为1000',
  `createTime` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updateTime` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `channelStatus` tinyint(4) unsigned NOT NULL DEFAULT '1' COMMENT '频道状态,1正常 2解散状态',
  `keyWords` varchar(32) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '关键字',

  PRIMARY KEY (`id`),
  UNIQUE KEY `channelID` (`channelID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='群聊频道表'

```

```sql
CREATE TABLE `tbl_channelList` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `channelID` varchar(20) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '频道编号，channelType channelBase拼接',
  `accountID` varchar(20) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '用户id',
	`createTime` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updateTime` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  `userStatus` tinyint(4) unsigned NOT NULL DEFAULT '1' COMMENT '频道状态,1正常 2、已退出  ，4黑名单',
  PRIMARY KEY (`id`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='群聊频道表'

```

redis
			KEY  												VALUE 				TYPE
			channel:${accountID}        需商定     SET
