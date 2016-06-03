## Unit 01
KISS
Keep It Small and Simple.

`gcc -o fred fred.c /usr/lib/libm.a`
`gcc -a fred fred.c -lm`
search the math library to link function.
libm.a
-lm : standard library function, if there a share library, auto choose it

`gcc -o x11fred -L/usr/openwin/lib x11fred.c -lx11`

archive
`gcc -c bill.c fred.c`
`ar crv libfoo.a bill.o fred.o`
`gcc -o program program.o libfoo.a`
`gcc -o program program.o -L. -lfoo`

`ldd program`


## Unit 02
`kill -HUP 1234 >killout 2>killerr`
`kill -1 1234 >killouterr 2>&1`



