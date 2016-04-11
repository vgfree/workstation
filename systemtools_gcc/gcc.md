### 编译简单C程序     
```c
#include <stdio.h>
int main(void)
{
        printf(“Hello, world!\n”);
        return 0;
}
```
`$ gcc -g -Wall hello.c -o hello`
* `hello` 可执行文件(机器码)    
* `-o`  指定机器码文件名(缺省 则输出文件为 a.out)
* `-Wall`  开启编译器警告
* `-g` 表示生成的目标文件中带调试信息(异常中止时生成core文件)

***
### 编译多个源文件     
```c
// hello.h

void hello (const char * name);
```
```c
// hello_fn.c

#include <stdio.h>
#include "hello.h"

void hello (const char * name)
{
        printf ("Hello, %s!\n", name);
}
```
```c
// hello.c

#include "hello.h"
int main(void)
{
        hello ("world");
        return 0;
}
```
`$ gcc -Wall hello.c hello_fn.c -o newhello`    

***
### 简单的Makefile文件       
```makefile
CC=gcc
CFLAGS=-Wall

hello: hello.o hello_fn.o

clean:
        rm -f hello hello.o hello_fn.o
```
* `CFLAGS` 编译预处理选项
* `-f` (force)抑制文件不存在时产生的错误消息

***
### 链接外部库       
库：预编译的目标文件(object files)集合      
静态库：特殊的存档文件(archive file)存储
