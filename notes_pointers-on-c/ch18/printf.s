<<<<<<< HEAD
|
| Need to print the three values x, y, and z.
|
	movl	z,sp@-		| Push args on the
	movl	y,sp@-		| stack in reverse
	movl	x,sp@-		| order: format, x,
	movl	#format,sp@-	| y, and z.
	jbsr	_printf		| Now call printf
	addl	#16,sp		| Clean up stack
	\&...
	.data
format:	.ascii	"x = %d, y = %d, and z = %d"
	.byte	012, 0		| Newline and null
	.even
x:	.long	25
y:	.long	45
z:	.long	50
=======
|
| Need to print the three values x, y, and z.
|
	movl	z,sp@-		| Push args on the
	movl	y,sp@-		| stack in reverse
	movl	x,sp@-		| order: format, x,
	movl	#format,sp@-	| y, and z.
	jbsr	_printf		| Now call printf
	addl	#16,sp		| Clean up stack
	\&...
	.data
format:	.ascii	"x = %d, y = %d, and z = %d"
	.byte	012, 0		| Newline and null
	.even
x:	.long	25
y:	.long	45
z:	.long	50
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
