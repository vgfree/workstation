<<<<<<< HEAD
/*
**  Copy the string contained in the second argument to the
** buffer specified by the first argument.
*/
void
strcpy( char *buffer, char const *string )
{
	/*
	** Copy characters until a NUL byte is copied.
	*/
	while( (*buffer++ = *string++) != '\0' )
		;
}
=======
/*
**  Copy the string contained in the second argument to the
** buffer specified by the first argument.
*/
void
strcpy( char *buffer, char const *string )
{
	/*
	** Copy characters until a NUL byte is copied.
	*/
	while( (*buffer++ = *string++) != '\0' )
		;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
