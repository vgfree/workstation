###
```C
// expression 为假，则先stderr打印一条出错信息，然后通过调用abort来中止程序
void assert( int expression );
```
### ZMQ
ZMQ是一个类似于Socket的一系列接口           
与Socket区别：              
1. Socket 端到端 (1:1), ZMQ 可以 N：M                         
2. BSD套接字：点对点，显式建立链接、销毁链接、选择协议(TCP/UDP)和处理错误, ZMQ屏蔽细节          
3. ZMQ用于node与node间通信，node是主机或进程         

### ZMQ 安装相关    

```
# 安装 zmq  (zeromq-devel-4.0.5-4.el7.x86_64版本)
yum install zeromq-devel

# 安装 libsodium
git clone git://github.com/jedisct1/libsodium.git
cd libsodium
./autogen.sh
./configure && make check
sudo make install
sudo ldconfig
cd ..

# 安装 libzmq
git clone git://github.com/zeromq/libzmq.git
cd libzmq
./autogen.sh
./configure && make check
sudo make install
sudo ldconfig
cd ..

# 安装 czmq
git clone git://github.com/zeromq/czmq.git
cd czmq
./autogen.sh
./configure && make check
sudo make install
sudo ldconfig
cd ..

# 使用方法
gcc -lczmq -lzmq myapp.c -o myapp
```
