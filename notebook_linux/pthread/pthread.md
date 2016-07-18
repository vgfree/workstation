1. 编译
`gcc filename.c -pthread`

2. 线程函数
```c++
// 创建新线程
pthread_create();

// 获取线程ID
pthread_self();

// 线程退出
 // 执行完后隐式退出
pthread_exit(); // 自己退出
pthread_cance(pthread_t thread); // 终止其他线程
pthread_join(); // 调用pthread_join的线程将被挂起直到指定的线程终止
```
3. 线程通信
线程互斥:
两个线程不能同时进入被互斥保护的代码
```c++
int x;	// 进程中的全局变量
pthread_mutex_t mutex;
pthread_mutex_init(&mutex, NULL); // 初始化互斥变量体mutex
pthread_mutex_lock(&mutex); // 给互斥体变量加锁
x++;	// 对变量x的操作
pthread_mutex_unlock(&mutex); // 给互斥体变量解除锁
```

线程同步:
线程等待某个事件的发生,只有等待的事件发生,线程才会继续执行, 否则就会挂起
多线程同步机制1: 条件变量(condition variable)
```c++
pthread_cond_t ; // 声明条件变量
pthread_con_init();	// 创建条件变量
// 等待条件变量被设置, 需要一个已经上锁的互斥体mutex
pthread_cond_wait (pthread_cond_t *cond, pthread_mutex_t *mutex);
pthread_cond_broadcast();	// 设置条件变量(使得事件发生)
pthread_cond_signal(); // 解除线程阻塞状态
pthread_cond_destroy(); // 释放一个条件变量资源
```
多线程同步机制2: 信号量
```c++
// 初始化一个信号量sem的值为val
sem_init(sem_t *sem, int pshared, unsigned int val);
sem_wait(sem_t *sem);	// 等待信号量, 调用时, 若sem为无状态,调用线程阻塞,
//等待信号量sem值增加成为有信号状态;若sem为有状态,调用线程顺序执行,信号量减一
sem_post(sem_t *sem); // 释放信号量, 调用后, 信号量sem值增加, 可以从无信号状态变为有信号状态
```


