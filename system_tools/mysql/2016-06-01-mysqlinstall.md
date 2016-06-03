---                                                                                                                                                                                                                                                  layout: post                                                                    
title: "MySQL 安装与配置"                                               
subtitle: "CentOS MySQL安装与配置"                                              
date: 2016-06-01                                                                
author: louis.tin                                                               
category: note                                                                  
tags: note mysql linux                                                          
finished: true                                                                  
---

## 1.  Install MySQL YUM repository   
Fedora  
```Shell
## Fedora 23 ##
dnf install https://dev.mysql.com/get/mysql57-community-release-fc23-7.noarch.rpm

## Fedora 22 ##
dnf install https://dev.mysql.com/get/mysql57-community-release-fc22-7.noarch.rpm
```

CentOS and REHL
```Shell
## CentOS 7 and Red Hat (RHEL) 7 ##
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm

## CentOS 6 and Red Hat (RHEL) 6 ##
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm
```

## 2. Update or Install MySQL
Fedora
```Shell
dnf install mysql-community-server
```

CentOS and REHL
```Shell
yum install mysql-community-server
```

## 3. Start MySQL server and autostart MySQL on boot
Fedora 23/22/21 and CentOS 7.2
```Shell
systemctl start mysqld.service ## use restart after update

systemctl enable mysqld.service
```

CentOS 6.7/5.11 and Red Hat (RHEL) 6.7/5.11
```Shell
/etc/init.d/mysql start ## use restart after update
## OR ##
service mysql start ## use restart after update

chkconfig --levels 235 mysqld on
```

## 4. Get Your Generated Random root Password
```Shell
grep 'A temporary password is generated for root@localhost' /var/log/mysqld.log |tail -1
```

## 5. MySQL Secure Installation
```Shell
/usr/bin/mysql_secure_installation
```
> Change root password , Y  
> Remove anonymous users , Y  
> Disallow root login remotely , n  
> Remove test database and access to it , Y   
> Reload privilege tables , Y

```Shell
mysqladmin -u root password [your_password_here]
```

## 6. Enable Remote Connection
### 1. Fedora 23/22/21 and CentOS/Red Hat (RHEL) 7.2
### 1.1 Add New Rule to Firewalld
```Shell
firewall-cmd --permanent --zone=public --add-service=mysql

## OR ##

firewall-cmd --permanent --zone=public --add --port=3306/tcp
```

### 1.2 Restart firewalld.service
```Shell
systemctl restart firewalld.service
```
### 2. Fedora 23/22/21 and CentOS/Red Hat (RHEL) 7.2
### 2.1 Edit /etc/sysconfig/iptables file
```Shell
nano -w /etc/sysconfig/iptables
```

### 2.2 Add following INPUT rule
```Shell
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT
```

## 6.3 Restart Iptables Firewall
```Shell
service iptables restart
## OR ##
/etc/init.d/iptables restart
```

## 6.4 Test remote connection
```Shell
mysql -h 10.0.15.25 -u myusername -p
```


***
## Set Character utf8
```MySQL
show variables like "%char%";
```

```MySQL
CREATE DATABASE `test`  
CHARACTER SET 'utf8'  
COLLATE 'utf8_general_ci';
```

```MySQL
CREATE TABLE `database_user` (  
`ID` varchar(40) NOT NULL default '',  
`UserID` varchar(40) NOT NULL default '',  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```
