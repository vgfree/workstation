http://www.cnblogs.com/ayanmw/p/3434028.html

查找 此文件 相关的文件：

updatedb

locate libmysqlclient.so

出现 在/usr/lib64/mysql/libmysqlclient.so

但是 

ll /usr/lib64/mysql/libmysqlclient.so
lrwxrwxrwx. 1 root root 24 11月 20 17:02 /usr/lib64/mysql/libmysqlclient.so ->
libmysqlclient.so.16.0.0

这个是一个软链接而已，原本的libmysqlclient.so.16.0.0却找不到。

查看当前系统安装的mysql的软件

rpm -qa|grep mysql
mysql-server-5.1.69-1.el6_4.x86_64
mysql-libs-5.1.69-1.el6_4.x86_64
mysql-devel-5.1.69-1.el6_4.x86_64
mysql-5.1.69-1.el6_4.x86_64

bmysqlclient.so 究竟是哪个包所带的呢？

rpm -ql mysql-server
rpm -ql mysql
rpm -ql mysql-devel
rpm -ql mysql-libs
终于找到了。甚至 my.cnf 和 ld.config 也在这个包里。
yum remove mysql-libs

发现居然要卸载许多依赖，这样不可以啊。

那就

yum reinstall mysql-libs -y 

安装好之后，就可以了。。

