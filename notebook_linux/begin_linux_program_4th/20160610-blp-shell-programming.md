---
title: Shell Programming
---
## 2.4 管道和重定向
```bash
# 标准输出与标准错误输出分开, 标准错误输出为追加写入
kill -HUP 1234 >killout.txt 2>>killerr.txt
# 将标准输出重定向到/dev/null(回收站会丢弃所有输出信息), 然后将标准错误输出重定向到与标准输出相同的地方
kill -l 1234 >/dev/null 2>&1
```
```bash
# 先按字母排序输出, 再去重, 再删除sh, 最后分页显示
ps -xo comm | sort | uniq | grep -v sh | more
```

## 2.5 Shell
* 脚本运行推荐 `./`
* 将脚本文件放在 `$HOME/bin` 中, 再将该路径加入 `.bash_profile` 的 `PATH` 中,即可执行
