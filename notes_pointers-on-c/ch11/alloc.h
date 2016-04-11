<<<<<<< HEAD
/*
** Definitions for a less error-prone memory allocator.
*/
#include <stdlib.h>

#define	malloc			DON'T CALL malloc DIRECTLY!
#define	MALLOC(num,type)	(type *)alloc( (num) * sizeof(type) )
extern	void	*alloc( size_t size );
=======
/*
** Definitions for a less error-prone memory allocator.
*/
#include <stdlib.h>

#define	malloc			DON'T CALL malloc DIRECTLY!
#define	MALLOC(num,type)	(type *)alloc( (num) * sizeof(type) )
extern	void	*alloc( size_t size );
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
