<<<<<<< HEAD
/*
** Copy the standard input to the standard output, converting
** all uppercase characters to lowercase.
*/
#include <stdio.h>

int
main( void )
{
	int	ch;

	while( (ch = getchar()) != EOF ){
		if( ch >= 'A' && ch <= 'Z' )
			ch += 'a' - 'A';
		putchar( ch );
	}
}
=======
/*
** Copy the standard input to the standard output, converting
** all uppercase characters to lowercase.
*/
#include <stdio.h>

int
main( void )
{
	int	ch;

	while( (ch = getchar()) != EOF ){
		if( ch >= 'A' && ch <= 'Z' )
			ch += 'a' - 'A';
		putchar( ch );
	}
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
