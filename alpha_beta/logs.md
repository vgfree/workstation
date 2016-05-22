### Linux 系统命令	

`netstat -lntp` : 查看开启端口		
`service sshd start` : 开启sshd		
`ll /proc/PID` : 查看进程启动路径	

mysql 自增从10000开始
```
CREATE TABLE TABLE_1 ( ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, //
		ID列为无符号整型，该列值不可以为空，并不可以重复，而且自增。
		NAME VARCHAR(5) NOT NULL  ) AUTO_INCREMENT = 10000;（ID列从10000开始自增）
```
