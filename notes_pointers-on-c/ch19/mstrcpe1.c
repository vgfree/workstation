<<<<<<< HEAD
/*
** String copy that returns a pointer to the end
** of the destination argument.  (Version 1)
*/

#include <string.h>

char *
my_strcpy_end( char *dst, char const *src )
{
	strcpy( dst, src );

	return dst + strlen( dst );
}
=======
/*
** String copy that returns a pointer to the end
** of the destination argument.  (Version 1)
*/

#include <string.h>

char *
my_strcpy_end( char *dst, char const *src )
{
	strcpy( dst, src );

	return dst + strlen( dst );
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
