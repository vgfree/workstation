module("transit_cfg")

OWN_INFO = {
	---- 本机ip,端口(线上ip为线上服务器的ip)
	current_host_ip = "127.0.0.1", 
	current_host_port = "80",
	
	---- **** 本地存储erramr的上一层目录名称,
	---- **** [注意后面不能带/],并且一定要有erramr文件夹的存在
	----线上path为“/data/nginx/transit/”
	current_local_path = "/tmp",

}
