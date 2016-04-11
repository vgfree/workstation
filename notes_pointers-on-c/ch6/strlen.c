<<<<<<< HEAD
/*
** Compute the length of a string.
*/

#include <stdlib.h>

size_t
strlen( char *string )
{
	int	length = 0;

	/*
	** Advance through the string, counting characters
	** until the terminating NUL byte is reached.
	*/
	while( *string++ != '\0' )
		length += 1;

	return length;
}
=======
/*
** Compute the length of a string.
*/

#include <stdlib.h>

size_t
strlen( char *string )
{
	int	length = 0;

	/*
	** Advance through the string, counting characters
	** until the terminating NUL byte is reached.
	*/
	while( *string++ != '\0' )
		length += 1;

	return length;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
