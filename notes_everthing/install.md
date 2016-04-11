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

### MySQL 安装
1. 下载mysql-5.7.11-1.el7.x86_64.rpm-bundle.tar			
   下载mysql-workbench-community-6.3.6-2.el7.x86_64.rpm
2. 解压后需要安装的是common libs client server devel
3. 安装workbench


