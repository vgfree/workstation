<<<<<<< HEAD
/*
** Extract whitespace-delimited tokens from a character array and
** print them one per line.
*/
#include <stdio.h>
#include <string.h>

void
print_tokens( char *line )
{
	static	char	whitespace[] = " \t\f\r\v\n";
	char	*token;

	for( token = strtok( line, whitespace );
	    token != NULL;
	    token = strtok( NULL, whitespace ) )
		printf( "Next token is %s\n", token );
}
=======
/*
** Extract whitespace-delimited tokens from a character array and
** print them one per line.
*/
#include <stdio.h>
#include <string.h>

void
print_tokens( char *line )
{
	static	char	whitespace[] = " \t\f\r\v\n";
	char	*token;

	for( token = strtok( line, whitespace );
	    token != NULL;
	    token = strtok( NULL, whitespace ) )
		printf( "Next token is %s\n", token );
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
