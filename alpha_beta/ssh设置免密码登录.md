1. ssh-keygen -t rsa  生成公钥		
2. 将 ~/.ssh/id_rsa.pub 拷贝到目标机 ~/.ssh 中
3. cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys	
4. 修改目标机权限	
	chmod 700 ~/.ssh	
	chmod 600 ~/.ssh/authorized_keys
