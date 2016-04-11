### 第一部分 概述
make 是一个工具，一个解释makefile中指令的命令工具

***
### 第二部分 关于程序的编译和链接
编译 compile： 把源文件编译成中间代码文件，即 .o 文件      
链接 link： 把大量ObjectFile合成执行文件

**源文件 -> 中间文件 -> 可执行文件**    
编译时，编译器只检测程序语法，和函数、变量是否被声明，如果未声明则会警告，但可以生成    
ObjectFile.     
链接时，链接器会在所有ObjectFile中找寻函数的实现，如果找不到，就会报链接错误。    
>链接器不管函数所在的源文件，只管函数的中间目标文件。有时源文件太多，编译生成的中间文         
件也很多，就需要将中间文件打包成 `.a` 文件        

***
### 第三部分 Makefile 介绍
#### 1. Makefile 规则
```makefile
target: prerequisites
        command
```
`target`  目标文件， .o / 可执行文件        
`prerequisites`  生成target 所需的依赖文件         
`command`  make 需要执行的命令(Shell命令)        
> prerequisites中如果有文件比target文件要新的话，command中的命令就会被执行    
  command 前以一个Tab键作为开始s

#### 2. 示例
```makefile
# 原始 Makefile

edit : main.o kbd.o command.o display.o insert.o search.o files.o utils.o
        cc -o edit main.o kbd.o command.o display.o insert.o search.o files.o utils.o

main.o : main.c defs.h
        cc -c main.c

kbd.o : kbd.c defs.h command.h
        cc -c kbd.c

command.o : command.c defs.h command.h
        cc -c command.c

display.o : display.c defs.h buffer.h
        cc -c display.c

insert.o : insert.c defs.h buffer.h
        cc -c insert.c

search.o : search.c defs.h buffer.h
        cc -c search.c

files.o : files.c defs.h buffer.h command.h
        cc -c files.c

utils.o : utils.c defs.h
        cc -c utils.c

clean :
        rm edit main.o kbd.o command.o display.o insert.o search.o files.o utils.o
```

#### 3. 工作过程
1. `make` 在当前目录下寻找 Makefile 文件
2. 在 Makefile 文件中寻找第一个目标文件，并作为文件最终目标文件
3. edit 不存在或依赖于后续的 .o 文件时间戳比 edit 文件要新，那么就执行后面的命令
4. 继续寻找 .o 文件的依赖性
5. .c .h 文件存在，`make` 生成 .o 文件，再用 .o 文件生成 edit 文件

#### 4. Makefile 中使用变量
```makefile
# 使用变量的 Makefile

objects = main.o kbd.o command.o display.o insert.o search.o files.o utils.o

edit : $(objects)
        cc -o edit $(objects)

main.o : main.c defs.h
        cc -c main.c

kbd.o : kbd.c defs.h command.h
        cc -c kbd.c

command.o : command.c defs.h command.h
        cc -c command.c

display.o : display.c defs.h buffer.h
        cc -c display.c

insert.o : insert.c defs.h buffer.h
        cc -c insert.c

search.o : search.c defs.h buffer.h
        cc -c search.c

files.o : files.c defs.h buffer.h command.h
        cc -c files.c

utils.o : utils.c defs.h
        cc -c utils.c

clean :
        rm edit $(objects)
```

#### 5. 让 `make` 自动推导     
只要 `make` 看到一个 .o 文件，就会自动将 .c 文件加入到依赖关系中；如果 `make` 找到一个         
whatever.o, 那么 whtaever.c 就会是其依赖文件， 并且 cc -c whatever.c 也会被推导出来         
```makefile
# make 隐晦规则

objects = main.o kbd.o command.o display.o insert.o search.o files.o utils.o

edit : $(objects)
        cc -o edit $(objects)

main.o : defs.h

kbd.o : defs.h command.h

command.o : defs.h command.h

display.o : defs.h buffer.h

insert.o : defs.h buffer.h

search.o : defs.h buffer.h

files.o : defs.h buffer.h command.h

utils.o : defs.h

.PHONY : clean

clean :
        rm edit $(objects)
```

#### 6. 另类风格的 Makefile
```makefile
# 另类风格的 Makefile

objects = main.o kbd.o command.o display.o insert.o search.o files.o utils.o

edit : $(objects)
        cc -o edit $(objects)

$(objects) : defs.h

kbd.o command.o files.o : command.h

display.o insert.o search.o files.o : buffer.h

.PHONY : clean

clean :
        rm edit $(objects)
```

#### 7. 清空目标文件的规则
```makefile
# 普通风格

clean:
        rm edit $(objects)
```

```makefile
# 稳健风格

.PHONY : clean

clean :
        -rm edit $(objects)
```
> `.PHONY` 伪目标    
  `-rm` 表示忽略个别可能的问题，继续执行

### 第四部分 Makefile 总述
#### 1. Makefile 组成
显式规则、隐晦规则、变量定义、文件指示、注释          
1. 显式规则：说明如何生成一个或多个目标文件
2. 隐晦规则：利用了`make` 的自动推导功能               
3. 变量定义：定义的变量在执行时都会被扩展到相应的引用位置上         
4. 文件指示：
 * 在一个Makefile中引用另一个Makefile，(类比 #include)     
 * 根据某些情况指定Makefile中的有效部分，(类比 #define)
 * 定义一个多行命令
5. 注释： #

#### 2. 命名规则
Makefile

#### 3. 引用其他 Makefile
`include <filename>`    
>* include：前面可以有空格，但是不能有 `Tab`     
* filename：可以是当前系统Shell的文件模式(可以包含路径和通配符)  

当有 a.mk b.mk c.mk foo.make 和 $(bar) (包含有 e.mk f.mk)
```makefile
include foo.make *.mk $(bar)
```
等价于
```makefile
include foo.make a.mk b.mk c.mk e.mk f.mk
```
> * 可选参数 `-I` 或 `--include-dirs` 指定参数目录
* 目录 `<prefix>/include` (`/usr/local/include` 或 `/usr/include`) 存在，`make`       
也会去寻找
* `-include <filename>`  忽略错误

#### 4. 环境变量
如果当前环境中定义了环境变量 MAKEFILES，那么，`make` 会把这个变量中的值做一个类似于      
include的动作。这个变量中的值是其它Makefile, 使用空格分开。注意，和include不同的是，          
从这个环境变量中引入的Makefile 的 "目标" 不会起作用。      
**建议不要使用环境变量**

### 5. make 的工作方式
make 的工作执行步骤：
1. 读入所有的 Makefile。
2. 读入被 include 的其它 Makefile。
3. 初始化文件中的变量。
4. 推导隐晦规则,并分析所有规则。
5. 为所有的目标文件创建依赖关系链。
6. 根据依赖关系,决定哪些目标要重新生成。
7. 执行生成命令。

***
### 第五部分 书写规则
#### 1. 规则举例
依赖关系 & 生成目标的方法          
最终目标：第一条规则中的第一条目标

#### 2. 规则语法    
```makefile
targets : prerequisites
        command
# 或者
targets : prerequisites ; command
```
#### 3. 在规则中使用通配符
```makefile
*
?
...
```

#### 4. 文件搜寻  
**方法一**  
使用变量 *VPATH*    
`VPATH = src:../headers`        
`make` 目标及依赖文件搜索目录: `.`  `src` 和 `../headers`   
目录分隔符 `:`

**方法二**
使用make关键字vpath(可以指定不同的文件在不同的搜索目录中)
1. `vpath <pattern> <directories>`      
为符合模式<pattern>的文件指定搜索目录<directories>
```makefile
vpath %.h ../headers
```   
2. `vpath <pattern>`    
清除符合模式<pattern>的文件搜索目录  
```makefile
vpath %.c foo
vpath % blish
vpath %.c bar
# 搜索.c文件顺序 foo blish bar
```
3. `vpath`      
清除所有已被设置好的文件搜索目录        
```makefile
vpath %.c foo:bar
vpath % blish
# 搜索.c文件顺序 foo bar blish
```

#### 5. 伪目标     
伪目标只是一个标签，利用.PHONY 显式指明一个目标是伪目标，无论该文件是否存在，都可以运行
```makefile
.PHONY: clean
clean:
        rm *.o temp
```
伪目标没有依赖文件，但是也可以指定，伪目标也可以作为"默认目标"：
```makefile
all : prog1 prog2 prog3
.PHONY : all

prog1 : prog1.o utils.o
        cc -o prog1 prog1.o utils.o

prog2 : prog2.o
        cc -o prog2 prog2.o

prog3 : prog3.o sort.o utils.o
        cc -o prog3 prog3.o sort.o utils.o
# 一次性生成多个目标文件，且目标也可以成为依赖
```
```makefile
.PHONY: cleanall cleanobj cleandiff

cleanall : cleanobj cleandiff
        rm program

cleanobj :
        rm *.o

cleandiff :
        rm *.diff
# make cleanall/cleanobj/cleandiff 执行相应操作
# 伪目标也可以成为依赖
```

#### 6. 多目标     
适用：多目标，且依赖于同一文件，生成的命令也大体相似      
自动化变量："$@",表示目前规则中所有目标集合        
```makefile
bigoutput littleoutput : text.g
        generate text.g -$(subst output,,$@) > $@

# 等价于

bigoutput : text.g
        generate text.g -big > bigoutput

littleoutput : text.g
        generate text.g -little > littleoutput

# -$(subst output,,$@)
# $ 表示执行一个Makefile函数subst,后面为参数
```      

#### 7. 静态模式    
适用：更加容易的定义多目标规则
```makefile
<targets ...>: <target-pattern>: <prereq-patterns ...>
        <commands>
```
```makefile
objects = foo.o bar.o

all: $(objects)

$(objects): %.o: %.c
        $(CC) -c $(CFLAGS) $< -o $@

# 目标从 $objects 中获取，%.o 表示要所有以 .o 结尾的目标
# 依赖模式 %.c 取模式 %.o 的 % ，并为其加上 .c 后缀，得到依赖目标
# $< 自动化变量：所有的依赖目标集
# $@ 自动化变量：目标集

# 等价于

foo.o : foo.c
        $(CC) -c $(CFLAGS) foo.c -o foo.o

bar.o : bar.c
        $(CC) -c $(CFLAGS) bar.c -o bar.o
```
```makefile
files = foo.elc bar.o lose.o

$(filter %.o,$(files)): %.o: %.c
        $(CC) -c $(CFLAGS) $< -o $@

$(filter %.elc,$(files)): %.elc: %.el
        emacs -f batch-byte-compile $<
# $(filter %.o,$(files)) 表示调用filter函数，过滤 $filter 集，只要其中的 %.o
```

#### 8. 自动生成依赖性
适用： 在编译器生成的依赖关系中加入 .d 文件的依赖
```makefile
# 所有 .d 文件(存放对应.c文件的依赖关系)依赖于 .c 文件
%.d: %.c        
# rm -f $@; 删除所有依赖文件 (.d)
        @set -e; rm -f $@; \
# 为每个依赖文件(.c) $< 生成依赖文件 (.d) ,如 main.d.8998
        $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
# 利用sed命令做一个替换
        sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
# 删除临时文件
        rm -f $@.$$$$
```
```makefile
sources = foo.c bar.c
include $(sources:.c=.d)
# include 引入其他 Makefile 文件， .c=.d 将变量$(sources)所有的.c替换为.d
```

***
### 第六部分 书写命令   
#### 1. 显示命令    
```makefile
# 不显示命令
@echo 正在编译...
# 输出 "正在编译..."
```
make 执行时， 参数 -n / --just-print  , 只显示命令，不执行
             参数 -s / --slient      , 全面禁止命令显示

#### 2. 命令执行    
当上一条命令的结果应用于下一条命令时，使用分号分隔
```makefile
exec:
        cd /home/louis; pwd
```

#### 3. 命令出错    
make命令运行完毕后，make会检测返回码，非零时表示出错,则退出      
忽略错误方法：
1. 命令行前加 `-`, 如 `-rm -f *.o`
2. make 加参数 `-i` / `--ignore-errors`, 忽略Makefile中所有错误    
      一个规则是以".IGNORE"作为目标，那么这个规则中所有命令都会忽略错误
3. 参数 `-k` / `--keep-going`, 中止该规则，继续执行其他规则

#### 4. 嵌套执行 make       
在大型工程中，可以在每个目录中都书写一个该目录的Makefile, 有利于模块编译和分段编译  
```makefile
subsystem:
        cd subdir && $(MAKE)

# 等价于   

subsystem:
        $(MAKE) -C subdir
```

#### 5. 定义命令包
适用：在Makefile中出现一些相同的命令序列，为其定义一个变量
```makefile
define run-yacc
        yacc $(firstword $^)
        mv y.tab.c $@
endef

foo.c : foo.y
        $(run-yacc)
# $^ foo.y   $@ foo.c
```

### 第七部分 使用变量
命名规则：字符 数字 下划线
#### 1. 变量基础    
```makefile
# 变量声明时需要赋初值
# 引用时： $()
objects = program.o foo.o utils.o
program : $(objects)
        cc -o program $(objects)

$(objects) : defs.h
```

#### 2. 变量中的变量  
定义变量的值：         
1. =        

```makefile
# 右侧变量的值不一定要是已定义好的值
# 在递归中会死循环

CFLAGS = $(include_dirs) -O
include_dirs = -Ifoo -Ibar
```     

2. ：=   只能使用前面已经定义好的变量          

```makefile
# 定义一个空格变量
nullstring :=
space := $(nullstring) # end of the line
```
```makefile
# 注意此处绝对地址后有四个空格，和字面看起来不一样
dir := /foo/bar # directory to put the frobs in
```     

3. ?=           

```makefile
# 如果FOO没有定义过，那么值就为 bar，已定义就什么也不做
FOO ?= bar
```     

#### 3. 变量的高级用法
**变量值的替换**
* 替换共有部分     
```makefile
# 替换结果 a.c b.c c.c
foo := a.o b.o c.o
bar := $(foo:.o=.c)
```
* 静态模式替换
```makefile
foo := a.o b.o c.o
bar := $(foo:%.o=%.c)           
```     
**变量值再当作变量**
```makefile
x = variable1
variable2 := Hello
y = $(subst 1,2,$(x))
z = y
a := $($($(z)))
# $(x) 为variable1，subst函数将1替换为2，变为variable2，再取值，最终为Hello
```
```makefile
first_second = Hello
a = first
b = second
all = $($a_$b)
# Hello
```

#### 4. 追加变量值   
如果变量之前没有定义过，+= 等价于 =    
前面有变量定义， += 会继承于前次操作的赋值符

```makefile
variable := value
variable += more

# 等价于

variable := value
variable := $(variable) more
```
```makefile
# 特别的，此时为value more
variable = value
variable += more
```

#### 5. override 指示符    
如果有变量是通过make的命令行参数设置的，那么Makefile中对这个变量的赋值会被忽略   
```makefile
override <variable> := <value>
override <variable> += <more text>
```

#### 6. 多行变量    
define后跟变量名，重起一行定义变量的值，以endef结束。变量值可以包含函数、命令、文字或变量              
```makefile
define two-lines
        echo foo
        echo $(bar)
endef
# 命令需以Tab开头
```

#### 7. 环境变量 CFLAGS      
make运行时的系统环境变量可以在make开始运行时被载入到Makefile文件中，如果Makefile文件中已        
定义这个变量或这个变量由make命令行带入，那么系统的环境变量值将会被覆盖。          
Makefile中定义环境变量使用定义值，没有定义则使用系统环境变量值。    
make嵌套调用时，上层Makefile中定义的变量会以系统环境变量的方式传递到下层Makefile中(命令行
中的直接传递，Makefile中的需要使用export关键字)         

#### 8. 目标变量    
设置局部变量  
```makefile
# variable-assignment 可以为各种赋值表达式
<target ...> : <variable-assignment>
<target ...> : override <variable-assignment>
```

```makefile
# 不论全局 $(CFLAGS) 值是什么，在prog目标以及其引发的所有规则中 值都为 -g
prog : CFLAGS = -g
prog : prog.o foo.o bar.o
        $(CC) $(CFLAGS) prog.o foo.o bar.o

prog.o : prog.c
        $(CC) $(CFLAGS) prog.c

foo.o : foo.c
        $(CC) $(CFLAGS) foo.c

bar.o : bar.c
        $(CC) $(CFLAGS) bar.c
```

#### 9. 模式变量    
可以给定一种模式，把变量定义在符合这种模式的所有目标上  
```makefile
# 语法
<pattern ...> : <variable-assignment>
<pattern ...> : override <variable-assignment>
```

```makefile
%.o : CFLAGS = -O
```

***
### 第八部分 使用条件判断
让 make 在运行时根据不同情况选择不同的执行分支。
#### 1. 示例
```makefile
# 判断 $(CC) 是否为 gcc，如果是，使用GNU函数编译目标
libs_for_gcc = -lgnu
normal_libs =

foo: $(objects)

ifeq ($(CC), gcc)
        $(CC) -o foo $(objects) $(libs_for_gcc)
else
        $(CC) -o foo $(objects) $(normal_libs)
endif
```
```makefile
# 另一种写法
libs_for_gcc = -lgnu
normal_libs =

ifeq ($(CC),gcc)
libs=$(libs_for_gcc)
else
libs=$(normal_libs)
endif

foo: $(objects)
        $(CC) -o foo $(objects) $(libs)
```

#### 2. 语法
```makefile
# 条件表达式语法
# Tab 不被允许
# 自动化变量($@等)在运行时才生成，所以尽量不要放入条件表达式
# <conditional-directive> 条件关键字
<conditional-directive>
<text-if-true>
endif

# 以及

<conditional-directive>
<text-if-true>
else
<text-if-false>
endif
```
**条件关键字**
* `ifeq (<argv1>, <argv2>)` 比较两个参数是否相同,相同为真，不同为假
```makefile
ifeq (<argv1>, <argv2>)
```
```makefile
# 使用 make 函数
# strip 函数返回值为 空 ，则成立
ifeq ($(strip $(foo)), )
<text-if-empty>
endif
```
* `ifneq (<argv1>, <argv2>)` 相同为假，不同为真


* `ifdef <variable-name>` 判断变量值非空为真，否则为假

```makefile
# 此时为 yes
bar =
foo = $(bar)

ifdef foo
frobozz = yes
else
frobozz = no
endif
```
```makefile
# 此时为 no
foo =

ifdef foo
frobozz = yes
else
frobozz = no
endif
```
* `ifndef <variable-name>` 判断变量值空为真，否则为假

***
### 第九部分 使用函数
#### 1. 函数调用语法
`$(<function> <arguments>)`
><function> 函数名
><arguments> 函数参数，参数间以`,`分隔

```makefile
# space 定义空格
# subst 替换函数 “被替换字符串， 替换字符串， 替换操作作用字符串”
# 操作结果 "a b c" -> "a,b,c"
comma:= ,
empty:=
space:= $(empty) $(empty)
foo:= a b c
bar:= $(subst $(space), $(comma), $(foo))
```

#### 2. 字符串处理函数
* `$(subst <from>, <to>, <text>)` 字符串替换函数

* `$(patsubst <pattern>,<replacement>,<text>)` 模式字符串替换函数
```makefile
# 结果 x.c.o bar.o
$(patsubst %.c, %.o, x.c.c bar.c)
```
* `$(strip <string>)` 去掉 string 字串开头和结尾的空字符
```makefile
# "a b c " -> "a b c"
$(strip a b c )
```
* $(findstring <find>,<in>) 在字串<in>中查找<find>字串
```makefile
# 返回 a
$(findstring a,a b c)
# 返回空字符串""
$(findstring a,b c)
```
* `$(filter <pattern...>,<text>)` 过滤函数                 
以<pattern>模式过滤<text>字符串中的单词,保留符合模式<pattern>的单词      
        ```makefile
        # 返回 foo.c bar.c baz.s
        sources := foo.c bar.c baz.s ugh.h

        foo: $(sources)
                cc $(filter %.c %.s,$(sources)) -o foo
        ```
* `$(filter-out <pattern...>,<text>)` 反过滤函数             
以<pattern>模式过滤<text>字符串中的单词,去除符合模式<pattern>的单词。可以有多个模式；     
返回不符合模式<pattern>的字串     
```makefile
# 返回 foo.o bar.o
objects=main1.o foo.o main2.o bar.o
mains=main1.o main2.o
        $(filter-out $(mains),$(objects))
```          
* `$(sort <list>)` 排序函数         
给字符串<list>中的单词排序(升序)，返回排序后的字符串。         
```makefile
# 返回 bar foo lose
$(sort foo bar lose)
```
* `$(word <n>,<text>)` 取单词函数    
取字符串<text>中第<n>个单词，(从一开始)。返回字符串<text>中第<n>个单词。如果<n>比<text>      
中的单词数要大,那么返回空字符串。
```makefile
# 返回 bar
$(word 2, foo bar baz)
```
* `$(wordlist <s>,<e>,<text>)` 取单词串函数   
从字符串<text>中取从 s 开始到 e 的单词串。<s>和<e>是一个数字。        
返回字符串<text>中从<s>到<e>的单词字串。如果<s>比<text>中的单词数要大,那么返回空字符串。         
如果<e>大于<text>的单词数,那么返回从<s>开始,到<text>结束的单词串。
```makefile
# bar baz
$(wordlist 2, 3, foo bar baz)
```
* `$(words <text>)` 单词个数统计函数    
统计<text>中字符串中的单词个数，返回<text>中的单词数。       

```makefile
# 返回值 3
$(words, foo bar baz)

# 取<test> 中最有一个单词
$(word $(words <text>),<text>)
```
* `$(firstword <text>)` 首单词函数   
取字符串<text>中的第一个单词。返回字符串<text>的第一个单词   

```makefile
# 返回 foo
$(firstword foo bar)

# 等价于
$(word 1,<text>)
```

#### 3. 文件名操作函数
* `$(dir <names...>)`
名称:取目录函数——dir。  
功能:从文件名序列<names>中取出目录部分。目录部分是指最后一个反斜杠(“/”)之前的部分.        
如果没有反斜杠,那么返回“./”。       
返回:返回文件名序列<names>的目录部分。    
```makefile
# 返回值 src/
$(dir src/foo.c hacks)
```
* `$(notdir <names...>)`  
名称:取文件函数——notdir。       
功能:从文件名序列<names>中取出非目录部分。非目录部分是指最后一个反斜杠(“ /”)之后的部分。     
返回:返回文件名序列<names>的非目录部分。        
```makefile
# foo.c hacks
$(notdir src/foo.c hacks)
```
* `$(suffix <names...>)`        
名称:取后缀函数——suffix。       
功能:从文件名序列<names>中取出各个文件名的后缀。    
返回:返回文件名序列<names>的后缀序列,如果文件没有后缀,则返回空字串。         
```makefile
# .c .c
$(suffix src/foo.c src-1.0/bar.c hacks)
```
* `$(basename <names...>)`      
名称:取前缀函数——basename。     
功能:从文件名序列<names>中取出各个文件名的前缀部分。          
返回:返回文件名序列<names>的前缀序列,如果文件没有前缀,则返回空字串。         
```makefile
# src/foo src-1.0/bar hacks
$(basename src/foo.c src-1.0/bar.c hacks)
```
* `$(addsuffix <suffix>,<names...>)`    
名称:加后缀函数——addsuffix。    
功能:把后缀<suffix>加到<names>中的每个单词后面。        
返回:返回加过后缀的文件名序列。        
```makefile
# src/foo src/bar
$(addprefix src/,foo bar)
```
* `$(join <list1>,<list2>)`
名称:连接函数——join。          
功能:把<list2>中的单词对应地加到<list1>的单词后面。如果<list1>的单词个数要比       
<list2>的多,那么,<list1>中的多出来的单词将保持原样。如果<list2>的单词个数要比      
<list1>多,那么,<list2>多出来的单词将被复制到<list2>中。         
返回:返回连接过后的字符串。          
```makefile
# aaa111 bbb222 333
$(join aaa bbb , 111 222 333)
```

#### 4. foreach 函数      
`$(foreach <var>,<list>,<text>)`        
把参数 list 中的单词逐一取出放到参数 var 所指定的变量中,然后再执行 text 所包含的表达式。           
每一次 text 会返回一个字符串,循环过程中, text 的所返回的每个字符串会以空格分隔,最后当              
整个循环结束时, text 所返回的每个字符串所组成的整个字符串(以空格分隔)将会是 foreach              
函数的返回值。         
var 是一个临时的局部变量，foreach函数执行完毕后，参数 var 的变量将不再作用
```makefile
# a.o b.o c.o d.o
names := a b c d
files := $(foreach n,$(names),$(n).o)
```

#### 5. if 函数   
`$(if <condition>,<then-part>)` 或       
`$(if <condition>,<then-part>,<else-part>)`     
condition 为真，返回 then-part，为假，返回else-part，未定义返回空字串

#### 6. call 函数
`$(call <expression>,<parm1>,<parm2>,<parm3>...)`       
make 执行这个函数时,<expression>参数中的变量,如$(1),$(2),$(3)等,会被             
参数<parm1>,<parm2>,<parm3>依次取代。而<expression>的返回值就是 call 函数的返回值。          
```makefile
# foo 值为 b a
reverse = $(2) $(1)
foo = $(call reverse,a,b)
```

#### 7. origin 函数   
`$(origin <variable>)`          
variable 变量名，不可以被引用(不可以用$)；
Origin 函数会以其返回值来告诉你这个变量的“出生情况”                        

* `undefined`           
未被定义过          
* `default`             
默认定义                 
* `file`        
被定义在Makefile中   
* `command line`        
被命令行定义          
* `override`    
被override指示符重新定义、
* `automatic`           
命令运行中的自动化变量     

```makefile
# 如果变量 bletch 来源于环境，那么就重新定义，如果是非环境，就不重新定义
ifdef bletch
ifeq "$(origin bletch)" "environment"
bletch = barf, gag, etc.
endif
endif
```

#### 8. Shell 函数
把执行操作系统命令后的输出作为函数返回。            
```makefile
contents := $(shell cat foo)
files := $(shell echo *.c)
```             
#### 9. 控制 make 的函数             
make 提供一些函数来控制 make 的运行，检测Makefile 运行时的信息，并作出相应操作       
* $(error <text ...>)           
产生一个致命错误， text是错误信息  

        ```makefile
        # ERROR_001 定义了后执行时产生error调用    
        ifdef ERROR_001
        $(error error is $(ERROR_001))
        endif

        # err 被执行时发生 error 调用   
        ERR = $(error found an error!)
        .PHONY: err
        err: ; $(ERR)
        ```
* $(warning <text ...>)         
类似于error，不会让make退出，只是输出一段警告信息

***
### 第十部分 make 的运行       
#### 1. make 退出码        
> 0  表示成功       
> 1  运行时出现错误    
> 2  如果使用了 make 的`-q`选项，并且make使得一些目标不需要更新，返回2   

#### 2. 指定Makefile
`make –f hchen.mk` 指定执行的Makefile文件      

#### 3. 指定目标    
一般上，make最终目标是Makefile中的第一个目标        
```makefile
# 环境变量MAKECMDGOALS 会存放所指定的终极目标列表，如果未指定目标，则其为空
# 只要输入命令不是 make clean ，makefile就会自动包含 foo.d 和 bar.d这两个makefile文件
sources = foo.c bar.c
ifneq ( $(MAKECMDGOALS),clean)
include $(sources:.c=.d)
endif
```

```makefile
# make all 可以编译所有目标
# 如果 all 为第一目标，直接执行 make 就可以了
.PHONY: all
all: prog1 prog2 prog3 prog4
```
**伪目标**         
* `all`         
所有目标的目标，功能是编译所有目标       
* `clean`       
删除所有被 make 创建的文件        
* `install`     
安装已编译好的程序，即把目标执行文件拷贝到指定目标中去     
* `print`       
列出改变过的源文件       
* `tar`         
把源程序打包备份为一个tar文件        
* `dist`        
创建一个压缩文件，一般是把tar文件压缩为z或gz文件     
* `TAGS`        
更新所有目标，以备完整的重编译使用       
* `check` 和 `test`      
测试Makefile的流程   

#### 4. 检查规则            
* 不执行，只检查命令/执行序列        
`-n` `--just-print` `--dry-run` `--recon`       
* 不执行，只打印命令(不管目标是否更新)，把规则和连带规则下的命令打印出来，但不执行     
`-t` `--touch`          
* 把目标文件时间更新，但不执行文件(make假装编译目标，但不真正的编译，把目标变为已编译状态)               
`-q` `--question`       
* 找目标(目标存在，不输出也不编译，不存在，输出错误)            
`-W <file>` `--what-if=<file>` `--assume-new=<file>` `--new-file=<file>`        

#### 5. make 的参数        
* 忽略和其他版本的兼容性   
`-b` `-m`       
* 认为所有的目标都需要重编译         
`-B` `--always-make`            
* 指定读取makefile的目录       
`-C <dir>` `--directory=<dir>`  
含有多个-C时，此时后面的路径以前面的作为相对路径，并以最后的目录作为被指定目录        
`make -C ~/01.2016 -C/FILF` == `make -C ～/01.2016/FLIF`                 
* 输出make调试信息(options为等级)        
`--debug[=<options>]`    
>a -all，输出所有调试信息
>b -basic，输出简单调试信息(不需要重编译的目标)   
>v -verbose，输出包括哪个Makefile被解析，不需要被重编译的依赖文件等     
>i -implicit，输出所有隐含规则           
>j -jobs，输出执行规则中命令的详细信息，PID、返回码等        
>m -makefile，输出make读取Makefile,更新Makefile,执行Makefile的信息          

* 输出调试信息        
`-d` (等价于 `--debug=a`)          
* 指明环境变量的值覆盖Makefile中定义的变量的值            
`-e` `--environment-overrides`          
* 指定需要编译的Makefile       
`-f=<file>` `--file=<file>` `--makefile=<file>`         
* 显示帮助信息        
`-h` `--help`           
* 在执行时忽略所有错误    
`-i` `--ignore-errors`  
* 指定一个被包含makefile的搜索目标，可以使用多个-I参数来指定多个目录        
`-I <dir>` `--include-dir=<dir>`                
* 同时运行命令个数(多个-j,以最后一个为准)        
`-j [<jobsnum>]` `--jobs[=<jobsnum>]`           
* 出错也不停止，生成一个目标失败，依赖于其的目标也不会被执行         
`-k` `--keep-going`     
* 指定make运行命令的负载         
`-l <load>` `--load-average[=<load>]` `--max-load[=<load>]`             
* 仅输出执行过程中的命令序列，但并不执行           
`-o <file>` `--old-file=<file>` `--assume-old=<file>`   
* 输出makefile中的所有数据，包括所有的规则与变量           
`-p` `--print-date-base`                
* 不运行命令，也不输出。仅仅检查所指定的目标是否需要更新。为0需要更新，为2说明有错误发生          
`-q` `--question`       
* 禁止make使用任何隐晦规则        
`-r` `--no-builtin-rules`       
* 禁止make使用任何作用于变量上的隐晦规则         
`-R` `--no-builtin-variabes`            
* 在命令运行时不输出命令的输出        
`-s` `--silent` `--quiet`               
* 取消 -k 选项的作用(有时，make的选项是从环境变量MAKEFLAGS中继承下来的，使用此参数让环境          
变量中的 -k 选项失效)           
`-S` `--no-keep-going` `--stop`                 
* 只是把目标的修改日期变为最新(即阻止生成目标的命令)            
`-t` `--touch`  
* 输出make版本号     
`-v` `--version`        
* 输出运行makefile之前和之后的信息          
`-w` `--print-directory`        
* 禁止 -w 选项      
`--no-print-directory`          
* 假定目标 <file> 需要更新(和-n选项使用，会输出该目标更新时的运行动作。没有-n，使得       
<file>的修改时间为当前时间)       
`-W <file>` `--what-if=<file>` `--new-file=<file>` `--asume-file=<file>`        
* 只要make发现有未定义的变量，就输出警告信息       
`--warn-undefined-variables`            

***
### 第十一部分 隐含规则     
#### 1. 使用隐含规则          
make会试图自动推导产生这个目标的规则和命令，隐含规则是make事先约定好的一些规则.    
在make的隐含规则库中，每一条隐含规则都有其顺序，靠前的会被更频繁的用到，也会越先被执行.   
```makefile
foo : foo.o bar.o
        cc –o foo foo.o bar.o $(CFLAGS) $(LDFLAGS)
```

#### 2. 隐含规则一览          
`-r` 选项取消所有预设的隐含规则(对使用"后缀规则"定义的隐含规则无效)          
1. 编译C程序的隐含规则           
`*.o` 的目标依赖会自动推导 `*.c` ，并且其生成命令是`$(CC) -c $(CPPFLAGS) $(CFLAGS)`        
2. 编译C++的隐含规则           
`*.o`目标依赖会自动推导`*.cc \*.c`，并且生成命令是`$(CXX) -C $(CPPFLAGS) $(CFLAGS)`
3. 链接Object文件的隐含规则 ？      
`<n>` 目标依赖于`<n>.o`，通过运行C的编译器来运行链接程序生成，生成命令为     
`$(CC) $(LDFLAGS) <n>.o $(LOADLIBES) $(LDLIBS)` .这个规则对于只有一个源文件的工程有效，    
同时也对多个Object文件(由不同的源文件生成)的也有效。          
```makefile
x : y.o z.o
# x.c y.c z.c 存在时，隐含规则将执行以下命令
        cc -c x.c -o x.o
        cc -c y.c -o y.o
        cc -c z.c -o z.o
        cc x.o y.o z.o -o x
        rm -f x.o
        rm -f y.o
        rm -f z.o
```  

#### 3. 隐含规则使用的变量       
隐含规则中的变量分两种：一种是命令相关的，如`CC`；一种是参数相关的，如`CFLAGS`   
* **关于命令的变量**       
>**AR** 函数库打包程序， `ar`           
>**AS** 汇编语言编译程序， `as`  
>**CC** C语言编译程序， `cc`   
>**CXX** C++语言编译程序， `g++`       
>**CO** 从RCS文件中扩展文件程序， `co`     
>**CPP** C程序的预处理器(输出是标准输出设备)， `$(CC) -E`        
>**GET** 从SCCS文件中扩展文件的程序， `get`         
>**YACC** Yacc文法分析器(针对C语言)， `yacc`      
>**MAKEINFO** 转换Texinfo源文件(.text)到Info文件程序， `makeinfo`          
>**TEX** 从 TeX 源文件创建 TeX DVI 文件的程序， `tex`
>**TEXI2DVI** 从 Texinfo 源文件创建军 TeX DVI 文件的程序， `texi2dvi`                
>**WEAVE** 转换 Web 到 TeX 的程序， `weave`            
>**CWEAVE** 转换 C Web 到 TeX 的程序， `cweave`                
>**CTANGLE** 转换 C Web 到 C， `ctangle`            
>**RM** 删除文件命令， `rm –f`         

* **关于命令参数的变量**         
>**ARFLAGS** 函数库打包程序 AR 命令的参数。默认值是“rv”。                 
>**CFLAGS** C 语言编译器参数。          
>**CXXFLAGS** C++语言编译器参数。                       
>**COFLAGS** RCS 命令参数。                  
>**CPPFLAGS** C 预处理器参数。( C 和 Fortran 编译器也会用到)。                  
>**GFLAGS** SCCS “get”程序参数。                     
>**LDFLAGS** 链接器参数。(如:“ld”)                     
>**LFLAGS**  Lex 文法分析器参数。                       
>**YFLAGS** Yacc 文法分析器参数。                       

#### 4. 隐含规则链           
一个目标有时会被一系列的隐含规则所作用，那么将这一系列的隐含规则叫做"隐含规则链"       
* 生成的中间文件一般会被删除(`.SECONDARY : sec`阻止删除 或 以模式的方式(如%.o)来指定成       
伪目标`.PRECIOUS`的依赖目标)                                
* 被指定成目标或依赖目标的文件不能被当作中间文件(可使用如`.INTERMEDIATE：mid`强制声明)          
* 在隐含规则链中禁止同一个目标出现次数 >= 2，防止出现无限递归              
* 一些特殊隐含规则链会进行优化，不生成中间文件        

#### 5. 定义模式规则          
`%` 代表一个或多个字符   
1. 模式规则介绍       
目标中的"%"的值决定了依赖目标中的"%"的值         
2. 模式规则示例       
```makefile
%.o : %.c
        $(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
```
```makefile
# 两个目标时模式的
%.tab.c %.tab.h: %.y
        bison -d $<
```
> 把所有 * .y 文件都以 `bison -d * .y`执行，然后生成 * .tab.c 和 * .tab.h          

3. 自动化变量        
自动化变量,就是这种变量会把模式中所定义的一系列的文件自动地挨个取出,直至所有的符合模式的          
文件都取完了。这种自动化变量只应出现在规则的命令中。              
**$@**  
规则中的目标文件集       
**￥%**  
仅当目标是函数库文件时，表示规则中的目标成员名。        
目标为"foo.a(bar.o)" , `$%`为 bar.o, `$@`为 foo.a。如果目标不是函数库文件，则为空            
**$<**  
依赖目标中的第一个目标名字。(如果依赖目标以模式(即%)定义的，则为符合模式的一系列文件集)          
**$?**  
所有比目标新的依赖目标的集合，以空格分隔。   
**$^**  
所有的依赖目标(去重)的集合，以空格分隔。   
**$+**  
非去重的依赖目标集合。     
**$***  
表示目标模式中 % 及其之前的部分。      
目标：`dir/a.foo.b`，目标模式：`a.%.b`，则 $* 为`dir/a.foo`

这段太繁了，暂且按下不表    

4. 模式匹配         
`test.c` ，`%c` 中 % 代表 test      
依赖目标`src/eat`，`e%t` 中 % 代表 src/a,在被依赖于这个目标中模式`c%r`,为`src/car`           

5. 重载内建隐含规则     
看不懂     

#### 6. 老式风格的"后缀规则"     


### 第十二部分 使用 make 更新函数库文件       
函数库文件：程序编译中间文件Object的打包。        
#### 1. 函数库文件   
一个函数库文件由多个文件组成。         
archive(member)         
```makefile
foolib(hack.o) : hack.o         
        ar cr foolib hack.o
```
指定多个member      
foolib(hack.o kludge.o)  foolib(* .o)            

#### 2. 函数库成员的隐含规则  
当make搜索一个目标的隐含规则时，如果这个目标时"a(m)"形式的，其会把目标变为"(m)"         
```makefile
# make foo.a(bar.o)
        cc -c bar.c -o bar.o
        ar r foo.a bar.o
        rm -f bar.o
```
#### 3. 函数库文件的后缀规则      
```makefile
.c.a:
        $(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $*.o
        $(AR) r $@ $*.o
        $(RM) $*.o
# 等效于   
(%.o): %.c
        $(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $*.o
        $(AR) r $@ $*.o
        $(RM) $*.o
```      
