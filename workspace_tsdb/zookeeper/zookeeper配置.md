### /data/workstation_zookeeper/server1/zookeeper-3.3.6/conf

```
tickTime=2000                                                                                                          
initLimit=5                                                                     
syncLimit=2                                                                     
dataDir=/data/workstation_zookeeper/server1/data                                
dataLogDir=/data/workstation_zookeeper/server1/dataLog                          
clientPort=2181                                                                 
server.1=127.0.0.1:2888:3888                                                    
server.2=127.0.0.1:2889:3889                                                    
server.3=127.0.0.1:2890:3890                                                    
                                                                                
# 注意dataDir dataLogDir 的配置目录                                             
# 同一台机器配置多个server, 每个的clientPort都不同                              
# server.x 对应myid中的数字 后面的第一个端口用于集群成员信息交换,第二个端口用   
# 于leader挂掉时选举leader所用
```


