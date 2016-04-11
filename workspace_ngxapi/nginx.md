### nginx 安装及本地环境搭建  
1. 创建安装目录:/data/nginx    
（注：将自己安装的东西都放在data目录下，方便自己管理）     
2. 安装make：  yum -y install gcc automake autoconf libtool make
3. 安装gcc和g++: yum install gcc gcc-c++
4. 安装luajit(尽量安装最新版的)：从这个地址http://luajit.org/download.html下载 解压   
make && make install
5. nginx的安装和配置
从http://nginx.org/en/download.html下载安装包（到nginx官网去下载）
下载第三方模块
lua-nginx-module 				
git clone https://github.com/openresty/lua-nginx-module.git
cd lua-nginx-module  
git checkout v0.9.16 -b v0.9.16
echo-nginx-module				
git clone https://github.com/agentzh/echo-nginx-module.git

ngx_devel_kit		
git clone https://github.com/simpl/ngx_devel_kit.git

export LUAJIT_LIB=/usr/local//luajit/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0


./configure --prefix=/data/nginx \
                     --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
                     --add-module=/root/nginx_tar/nginx-module/ngx_devel_kit \
                     --add-module=/root/nginx_tar/nginx-module/lua-nginx-module \
                     --add-module=/root/nginx_tar/nginx-module/echo-nginx-module \
                     --with-http_ssl_module \
                     --with-debug
                     make && make install

### 线上测试方法    
> ip: 192.168.71.55     
> key: abcd@1234
> nginx重启： /data/nginx/sbin/nginx -s reload     
> 查看日志文件:tail -f /data/nginx/logs/*_openconfig.log   
> curl请求： curl http://192.168.71.55/openconfig -d "appKey=616515395"
> 测试文件： /data/nginx/transit/api/api_dk_openconfig.lua
> 远程连接redis:
        /data/nginx/transit/deploy/link.lua
        redis-cli -h 192.168.1.11 -p 6339

页面测试
> ip: 192.168.1.207
> key:mirrtalk




### 线上查询方法
ssh 172.16.51.19
mtdk mtdk@123   
/data/nginx/crazyapi/deploy/link.lua    

ssh 172.16.61.101     
mtdk mtdk@123  
/data/redis/bin
./redis-cli -h statistic.redis.daoke.com -p 6339

### 查看请求方法
grep "clientcustom/v2/getCatalogInfo" * -r    
clientcustom/deploy/clientcustom.conf     
搜索 getCatalogInfo
找到源代码位置 clientcustom/api/api_get_cataloginfo.lua    
在源代码中可以查看sql语句相关  
查看数据库用户名与密码 /clientcustom/deploy/link.lua
