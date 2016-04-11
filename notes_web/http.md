## HTTP 协议

1. 协议层	
2. HTTP请求内容		
3. HTTP响应内容
4. 常见错误状态码解读	
5. 分别就GET和POST请求写两个示例

**************

> * 基于TCP协议的**应用层**传输协议	
> * 客户端和服务端进行数据传输的一种规则	

## URL 
`http://host:port abs_path`	

Host:192.168.1.3:8088	

## HTTP 请求	
> * 请求行 + 消息报头 + 请求正文	

### 请求行	
*定义了本次请求的请求方式\请求地址\所遵循的HTTP协议版本*	
`GET /example.html HTTP/1.1 (CRLF)`	

### 消息报头	
*由一系列key-value组成,允许客户端向服务端发送一些附加信息或客户端自身信息*	
> * Accept	
	指定客户端接收哪些类型的信息.	
	Accept:text/html
> * Accept-Charset	
	制定客户端接收的字符集.缺省表示都可接受		
	Accept-Charset:gb2312
> * Accept-Encoding	
	指定可接受的内容编码.缺省表示都可接受			
	Accept-Encodin:gzip.deflate  
> * Accept-Language	
	指定一种自然语言.	
	Accept-Language:zh-cn
> * Authorization	
	证明客户端有权查看某个资源.	
	收到服务端401未授权响应代码,可发送包含Authorization请求报头域的请求,来要
	求服务器进行验证.	
> * Host	
	指定被请求资源的internet主机和端口号.	
> * User-Agent	
	允许客户端将OS,Browser等信息告诉服务端(可不使用).	

### 请求正文	
post请求包含正文, get没有	

## HTTP响应	
> * 状态行 + 消息报头 + 响应正文	

### 状态行	
> * HTTP协议版本 + 状态码 + 状态码描述	
`HTTP/1.1 200 OK (CRLF)`

### 状态码	
> * 1xx：指示信息--表示请求已接收，继续处理
> * 2xx：成功--表示请求已被成功接收、理解、接受
> * 3xx：重定向--要完成请求必须进行更进一步的操作
> * 4xx：客户端错误--请求有语法错误或请求无法实现
> * 5xx：服务器端错误--服务器未能实现合法的请求

	200 OK //客户端请求成功	
	400 Bad Request //客户端请求有语法错误，不能被服务器所理解	
	401 Unauthorized //请求未经授权，这个状态代码必须和WWW-Authenticate报
	//头域一起使用	
	403 Forbidden //服务器收到请求，但是拒绝提供服务	
	404 Not Found //请求资源不存在，eg：输入了错误的URL	
	500 Internal Server Error //服务器发生不可预期的错误	
	503 Server Unavailable
	//服务器当前不能处理客户端的请求，一段时间后,可能恢复正常	

### 消息报头

### 响应正文	
即返回的HTML文件正文
