foo=100
x=foo
y='$'$x
echo $y

eval z='$'$x
echo $z

# $可以给出一个变量的值的值
