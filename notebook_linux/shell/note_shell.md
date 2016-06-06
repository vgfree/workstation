```sh
#!/bin/bash

cd ~/workstation/notebook_linux/shell
mkdir shell_test
cd shell_test

for ((i=0;i<10;i++))
do
  touch test_$i.txt
done

# 等号两端不要空格
# 变量区分大小写
```

```sh
#!/bin/bash  

read var1
echo $var1

exit 0

# shell脚本能够对任何可以从命令行上调用的退出码进行判断
```

```sh
#!/bin/bash

var="Think Station"

echo "This is $var"
echo 'This is $var'
echo "This is \$var"

exit 0

# "" $ 正常替换, 字符串包含空格,需要双引号
# '' 原样输出, 不会替换
# \ 转义字符
```

```sh
echo $HOME
echo $PATH  # 以冒号分隔的用来搜索命令的目录列表
echo $0 # 就是文件名
echo $1
echo $# # 传递给脚本的参数个数
echo $$ # 进程号

exit 0
```

```sh
#!/bin/bash                                                                                   

if test -f testDemo_20160603.sh                                                 
then                                                                            
        echo "testDemo_20160603.sh exists."                                     
fi                                                                              

if [ -f demo.c ]                                                                
then                                                                            
        echo "test.c exists."                                                   
else                                                                            
        echo "I cannot find exists."                                            
fi                                                                              

exit 0

# 布尔判断命令 test 或 []
# -f 判断指定文件是否存在
```

```sh
#!/bin/bash                                                                     

var1=louis                                                                      
var2=tin                                                                        

if [ $var1 = $var2 ] # 等号两端有空格                                                            
then                                                                            
        echo "$var1 = $var2"                                                    
else                                                                            
        echo "var1 != $var2"                                                    
fi                                                                              

exit 0
```

```sh
#!/bin/bash                                                                                   

echo "Is it moring? please answer yes or no."                                   
read timeofday                                                                  

if [ "$timeofday" = "yes" ] # 注意这里的引号                                                    
then                                                                            
        echo "Good Moring."                                                     
elif [ "$timeofday" = "no" ]                                                    
then                                                                            
        echo "Good afternoon."                                                  
else                                                                            
        echo "Sorry, $timeofday not recognized. Enter yes or no."               
        exit 1                                                                  
fi                                                                              

exit 0
```

```sh
#!/bin/bash                                                                                   

for foo in louis shana miku                                                     
do                                                                              
        echo $foo                                                               
done                                                                            

for index in {0..100}                                                           
do                                                                              
        echo $index                                                             
done

exit 0
```
