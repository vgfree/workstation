### 第一步 加载内核	
/boot	

### 第二步 启动初始化进程	
/sbin/init	
pid为1,其他所有进程都由它衍生，为其子进程	

### 第三步 确定运行级别		
daemon 对应 windows的service	
针对不同的场合，linux允许分配不同的开机启动程序，叫做runlevel	
runlevel 0～6  
init可以去运行开机启动程序.	
init 首先读取 /etc/inittab	
再根据文件中的设置家在相应级别的程序	


