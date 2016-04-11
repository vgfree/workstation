<<<<<<< HEAD
/*
** Implementation for a less error-prone memory allocator.
*/
#include <stdio.h>
#include "alloc.h"
#undef	malloc

void	*
alloc( size_t size )
{
	void	*new_mem;

	/*
	** Ask for the requested memory, and check that we really
	** got it.
	*/
	new_mem = malloc( size );
	if( new_mem == NULL ){
		printf( "Out of memory!\en" );
		exit( 1 );
	}
	return new_mem;
}
=======
/*
** Implementation for a less error-prone memory allocator.
*/
#include <stdio.h>
#include "alloc.h"
#undef	malloc

void	*
alloc( size_t size )
{
	void	*new_mem;

	/*
	** Ask for the requested memory, and check that we really
	** got it.
	*/
	new_mem = malloc( size );
	if( new_mem == NULL ){
		printf( "Out of memory!\en" );
		exit( 1 );
	}
	return new_mem;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
