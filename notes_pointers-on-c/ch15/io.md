### 标准IO 和 文件IO
#### 文件IO   
不带缓存IO，每个read, write都调用内核中的一个系统调用
`open` `read` `write` `lseek` `close`   

#### 标准IO   
标准IO库处理很多细节，如缓存分配、以优化长度执行IO等    
三种缓存类型：
 * 全缓存：填满IO缓存后才执行实际IO操作（fflush在缓存未填满时执行IO操作）   
 * 行缓存：输入或输出中遇到换行符时，执行IO操作    
 * 无缓存：stderr   
`fopen` `fclose` ``
