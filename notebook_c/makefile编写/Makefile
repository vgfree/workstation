
objects = main.o add.o multi.o

math : $(objects)
	cc -o math $(objects)

main.o : add.h multi.h

add.o : add.h

multi.o : multi.c multi.h

clean :
	rm math $(objects)
