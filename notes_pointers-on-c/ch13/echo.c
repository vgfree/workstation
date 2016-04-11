<<<<<<< HEAD
/*
** A program to print its command line arguments.
*/
#include <stdio.h>
#include <stdlib.h>

int
main( int argc, char **argv )
{
	/*
	** Print arguments until a NULL pointer is reached (argc is
	** not used).  The program name is skipped.
	*/
	while( *++argv != NULL )
		printf( "%s\n", *argv );
	return EXIT_SUCCESS;
}
=======
/*
** A program to print its command line arguments.
*/
#include <stdio.h>
#include <stdlib.h>

int
main( int argc, char **argv )
{
	/*
	** Print arguments until a NULL pointer is reached (argc is
	** not used).  The program name is skipped.
	*/
	while( *++argv != NULL )
		printf( "%s\n", *argv );
	return EXIT_SUCCESS;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
