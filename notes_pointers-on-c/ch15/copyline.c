<<<<<<< HEAD
/*
** Copy the standard input to the standard output, line by line.
*/
#include <stdio.h>

#define	MAX_LINE_LENGTH		1024	/* longest line I can copy */

void
copylines( FILE *input, FILE *output )
{
	char	buffer[MAX_LINE_LENGTH];

	while( fgets( buffer, MAX_LINE_LENGTH, input ) != NULL )
		fputs( buffer, output );
}
=======
/*
** Copy the standard input to the standard output, line by line.
*/
#include <stdio.h>

#define	MAX_LINE_LENGTH		1024	/* longest line I can copy */

void
copylines( FILE *input, FILE *output )
{
	char	buffer[MAX_LINE_LENGTH];

	while( fgets( buffer, MAX_LINE_LENGTH, input ) != NULL )
		fputs( buffer, output );
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
