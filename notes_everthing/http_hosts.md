### hosts是什么
hosts文件是本机的一个DNS解析表，方便计算机的IP与域名之间的转换与解析

为了方便用户记忆，将IP变成一个个的域名在浏览器中进行访问，而这使得访问网站时要先要将其域名解析成IP。    
DNS(Domain Name Server)的作用就是进行IP解析，把域名对应到IP。

Hosts文件是用来提高解析效率，在进行DNS请求前，系统会先检查自己的hosts文件中是否有这个地址映射关系，     
如果有则调用这个IP地址映射，如果没有再向已知的DNS服务器提出域名解析，即Hosts请求级别比DNS高

### 一些概念
https: Hypertext Transfer Protocol Secure + SSL/TLS 即超文本传输协议+SSL/TLS,用以提供加密通讯及对网络   
服务器身份的鉴定。http 默认80端口，https 默认443端口    

域名: ip地址的名字      
www.google.com  主机名www+域google.com          

ip地址: Internet Protocol Address 互联网协议地址        

http 是HTTP协议运行在TCP之上，所有传输内容是明文，客户端和服务器都无法验证对方的身份    
https 时HTTP运行在SSL/TLS之上，SSL/TLS运行在TCP之上，所有传输内容都经过加密，加密采用对称加密，但对称   
加密的密钥用服务器方的证书进行了非对称加密。此外客户端可以验证服务器端的身份，如果配置了客户端验证，    
服务器方也可以验证客户端身份。          

### http 
HyperText Transfer Protocol，使得HTTP客户(如web客户端)能够从HTTP服务器(web服务器)请求信息和服务。       
HTTP遵循请求/应答模型(Request/Response)         
HTTP使用内容型，是指web服务器向web浏览器返回的文件都有与之相关的类型    
HTTP是一种无状态协议，即web浏览器和web服务器之间不需要建立持久的连接    
HTTP一次完整的通信过程中，web浏览器和web服务器之间将完成7个步骤：
        1. 建立TCP连接          
        2. web浏览器向web服务器发送请求命令     
        3. web浏览器发送请求头信息      
        4. web服务器应答        
        5. web服务器发送应答头信息      
        6. web服务器向浏览器发送数据    
        7. web服务器关闭TCP连接         

*****HTTP请求格式**    
```
 | 请求方法URL协议/版本
 | 请求头(Request Header)

 | 请求正文
```

请求方法URI协议/版本
```
 GET/sample.jspHTTP/1.1
```
请求方法，URI，协议和协议版本   

请求头 Request Header   
包含许多有关的客户端环境和请求正文的信息        
```
Accept:image/gif.image/jpeg.*/*
Accept-Language:zh-cn
Connection:Keep-Alive
Host:localhost
User-Agent:Mozila/4.0(compatible:MSIE5.01:Windows NT5.0)
Accept-Encoding:gzip,deflate.
```

请求正文        
请求头和=请求正文间空一格       
包含客户提交的查询字符串信息    

```
 username=jinqiao&password=1234
```

HTTP 请求方法   
GET     
表单数据作为URL的一部分向web服务器发送          
`Http://127.0.0.1/login.jsp?Name=zhangshi&Age=30&Submit=%cc%E+%BD%BB`

POST    
数据不是作为URL的一部分而是作为标准数据传送给web服务器


