### C++ 调用 C
`TestC.h`
```c  
#ifndef TESTC_H         // 头文件保护
#define TESTC_H
#ifdef __cplusplus      // 判断是C还是C++调用
extern "C" {            // 通知编译器将extern "C" 所包含的代码按照C的方式编译和链接
#endif
int add(int a, int b);

#ifdef __cplusplus
}
#endif
#endif /* TESTC_H */
```
`TestC.c`
```c
#include "TestC.h"

int add(int a, int b)
{         
        return (a + b);
}
```

`TestCpp.cpp`
```c++
#include "stdio.h"
extern "C"
{
#include "TestC.h"
}

int main()
{
        printf("add = %d\n", add(2, 5));

        return 0;
}
```
**编译方法：**   
1. 生成目标文件 TestC.o    
`gcc -c TestC.c`   
2. 编译C++文件   
`g++ -o TestCpp TestCpp.cpp TestC.o`

>**Tips： 如何创建静态库**      
 *a.c b.c c.c 提供了C++所需的接口*
1. 编译目标文件 `gcc -c a.c b.c c.c`
2. 创建静态库文件libtest.a `ar cr libtest.a a.o b.o c.o`
3. 生成可执行文件my.exe `g++ -o my.exe my.cpp -L/home/aaa/lib -ltest`    
/home/aaa/lib 为静态库文件存放绝对路径
***
>**Tips: 为什么使用extern "C"**   
在C++中，为了支持重载机制，在编译生成的汇编代码中，要对函数的名字进行一些处理，加入比如函数
的返回类型等；而在C中，只是简单的函数名字，不会加入其他信息。

### C 调用 C++
`TestClass.h`
```c
class HJH       // 定义并实现了类 HJH 这个类只有一个 add 方法
{  
public:  
        int add(int a, int b)
        {
                return (a + b);
        }
};
```
`TestCpp.cpp`
```c++
#include "TestClass.h"
extern "C" int add_cpp(int a, int b);   // 将add_cpp 函数进行外部声明为 C
// 定义并实现一个函数 add_cpp ,函数中定义一个HJH类对象并调用该对象的add方法
int add_cpp(int a, int b)       
{
        HJH hjh;
        return hjh.add(a, b);
}
```
`TestC.c`
```c
#include "stdio.h"
// 进行外部声明，通知编译器说明这个函数是在其他文件中实现的(extern 后不加 C)
extern int add_cpp(int a, int b);
int main()
{
        printf("add_cpp = %d\n", add_cpp(2, 5));

        return 0;
}
```
**编译方法**
1. 先编译.cpp文件
`gcc -c TestCpp.cpp`   生成 TestCpp.o
2. 再编译.c文件
`gcc -c TestC.c`        生成 TestC.o
3. 生成可执行文件
`gcc TestCpp.o TestC.o -o TestC`
