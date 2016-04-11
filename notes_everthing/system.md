## 屏幕扩展：
 `xrandr --output VGA-1 --left-of LVDS-1 --auto`
***
## 安装无线网卡驱动 (自从装了CentOS 7，无线网卡就再也不是问题了)
 ```
 $iwconfig  //检查
 $lspci | grep -i network //查看型号
 $uname -r  // 查看系统内核
  //http://www.realtek.com.tw/downloads/downloadsView.aspx?Langid=1&PFid=48&Level=5&Conn=4&ProdID=228&DownTypeID=3&GetDown=false&Downloads=true    下载地址
 $yum install gcc -y //安装编译工具
 $ yum install kernel-devel -y
 $ make
 $ make install
 ```
***
## 禁用触摸板
```
$ yum install xorg-x11-apps
$ xinput list
$ xinput set-int-prop 13 "Device Enabled" 8 0  //开启则为1
```
***
## 查看内核
```
cat /boot/grub/grub.conf
```
***
## yum 源更新
```
 cd /etc/yum.repos.d/
 把备份文件拷贝过来
 yum makecache
```
***
## GDB 多线程调试
```
 gdb test
 b main
 r
 info threads
 thread 1
 set scheduler-locking on
 b kv_handler_create
 r
 layout
```
***
## 师姐ip
```
 192.168.11.198
```
***
## 主机ip
```
daoke-c 192.168.11.238
daokeoffice 192.168.31.183
```
***
## git
```
git checkout master     # 从工作分支切换到 master 分支
git pull origin         # 更新服务器上的修改
git merge dev_branch    # 合并工作分支
git reset origin        # 清除工作分支上的提交信息，但所有修改仍保留
git commit -a -m "msg"  # 编写提交信息
git push origin HEAD:refs/for/master  # 将修改提交到服务器
```
***
#### supex 并发测试
前提条件： 在supex/program/MMR 中make生成可执行文件rta
```
$ ssh root@192.168.1.12
$ _9e=6nV17eE.%MZ'yX0m

supex/program/MMR
        $ gdb rta
          r
启动 redis-server &
supex/test
        # luajit test_file.lua
```
***
#### FLIF 环境搭建
```
1. 安装 libpng-devel
        yum install libpng-devel
2. 安装 libsdl2-dev （比较复杂，不知道哪一个安装成功的）
        yum install SDL2-devel
        rpm -i SDL-1.2.15-14.el7.i686.rpm
        yum localinstall SDL-1.2.15-14.el7.i686.rpm
        yum install SDL
        yum search libsdl
        yum install libpng-devel
3. 注意看 /usr/include 中有没有 SDL
4. 安装完 ldconfig
```
***
#### apue 环境搭建
```
1. cp apue.3e/include/apue.h /usr/include
2. cp apue.3e/lib/error.c /usr/include
3. 在apue.h最后的#endif 前添加 #include "error.c"
```

#### 修改用户组
```
chown miku:miku lua_api/ -R
```

#### VPN密码

