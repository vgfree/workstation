1. 两种 internet sockets
SOCK_STREAM  TCP 在传输层将数据分隔
SOCK_DGRAM   UDP 一般不分割，过大时在IP层进行分割

2. 数据打包
[Ethernet [IP [UDP [TFTP [Data]]]]]

