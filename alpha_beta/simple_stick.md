### 04-19-2016
上午:
> * 将上线的三个接口利用https调通	
> * 编写修改个人头像接口

### 04-20-2016	
#### 1. 在修改个人头像中,添加redis                              
192.168.1.12/data/redis                                                         
添加redis7505.conf  redis7505.conf                                              
添加data7505 data7507                                                           
向 start.sh添加以上两个文件                                                     
--> $ redis-server ./redis.conf                                                 
完成了数据库的添加
