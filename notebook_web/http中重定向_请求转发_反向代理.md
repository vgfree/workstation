转发是服务器行为，重定向是客户端行为.

重定向
其实是两次request	
第一次，客户端requestA,服务器响应，并response回来，告诉浏览器，你应该去B。这个	
时候IE可以看到地址变了，而且历史的回退按钮也亮了。重定向可以访问自己web应用以外		
的资源。在重定向的过程中，传输的信息会被丢失。		

请求转发	
是服务器内部把对一个request/response的处理权，移交给另外一个对于客户端而言，	
它只知道自己最早请求的那个A，而不知道中间的B，甚至C、D。传输的信息不会丢失。	

反向代理 Reverse Proxy		
以代理服务器来接受internet上的连接请求，然后将请求转发给内部网络上的服务器；同	
时将从服务器上得到的结果返回给internet上请求连接的客户端，此时代理服务器对外就	
表现为一个服务器.	
反向代理的两种模型：作为内容服务器的替身 作为内容服务器的负载均衡器	
客户端 --> 反向代理服务器 --> 服务器	
代理的是服务器，数据有可能是从其他服务器取得的		

正向代理	
客户端 --> 代理服务器 --> 原始服务器	
代理的是客户端
原始服务器有可能并不知道时客户端发出的请求，因为直接请求来自于代理服务器，返回	
数据也是直接返回给代理服务器


