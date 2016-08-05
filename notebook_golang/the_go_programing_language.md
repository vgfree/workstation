

3.5.1 其他语言接口
  接口, A对B不一定完全依赖, 那么定义一个interface, 然后B实现它;当依赖C时, C来实现它

3.5.2 非侵入式接口


4.5 channel
```
chs := make(chan int, 10)
for ch := range chs {

}
ch1 := <-chan int(chs)
ch2 := chan<- int(chs)
close(ch)
_, ok := <-ch
```


