### 

> URL : Universal Resource Locator 统一资源定位符		
> URI : Universal Resource Identifier 统一资源标志符	
> URN : Universal Resource Name 统一资源名称	

URL: www.xxx.com/hello/sayHello.do
URI: hello/sayHello.do		
URN: sayHello.do	

URI 可以分为URL, URN或同时具备locators 和names 特性的一个东西, URN就像一个人的	
名字, URL就像一个人的地址. URN确定了资源的身份, URL提供了找到他的方式.		

URL是 URN的一种		
URL比URI多的就是访问机制(网络位置), e.g. http:// or ftp://	

URI 示例(包含访问机制的也是URL)
```
ftp://ftp.is.co.za/rfc/rfc1808.txt (also a URL because of the protocol)
http://www.ietf.org/rfc/rfc2396.txt (also a URL because of the protocol)
ldap://[2001:db8::7]/c=GB?objectClass?one (also a URL because of the protocol)
mailto:John.Doe@example.com (also a URL because of the protocol)
news:comp.infosystems.www.servers.unix (also a URL because of the protocol)
tel:+1-816-555-1212
telnet://192.0.2.16:80/ (also a URL because of the protocol)
urn:oasis:names:specification:docbook:dtd:xml:4.1.2
```

形如 `files.hp.com` 的是URI ,因为没有访问机制,他可以对应不同的协议和端口	
如: http://files.hp.com		
ftp://files.hp.com
