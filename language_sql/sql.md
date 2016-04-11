### 创建mysql用户	
1. 创建用户	
`create user 'username'@'hostname' identified by 'passwprd'`
hostname : localhost 或 % (可从任意远程主机登陆)	

2. 授权		
`grant all on databasename.tablename to 'username'@'hostname'`		
databasename\tablename 可使用通配符 *	

3. 删除用户
`drop user 'username'@'hostname'`



