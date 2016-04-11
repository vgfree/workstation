<<<<<<< HEAD
/*
** Take an integer value (unsigned), convert it to characters, and
** print it.  Leading zeros are suppressed.
*/
#include <stdio.h>

void
binary_to_ascii( unsigned int value )
{
	unsigned int	quotient;

	quotient = value / 10;
	if( quotient != 0 )
		binary_to_ascii( quotient );
	printf("%c\n", value % 10 + '0' );
}

int main()
{
        unsigned int value = 4267;
        void binary_to_ascii(value);

        return 0;
}
=======
/*
** Take an integer value (unsigned), convert it to characters, and
** print it.  Leading zeros are suppressed.
*/
#include <stdio.h>

void
binary_to_ascii( unsigned int value )
{
	unsigned int	quotient;

	quotient = value / 10;
	if( quotient != 0 )
		binary_to_ascii( quotient );
	printf("%c\n", value % 10 + '0' );
}

int main()
{
        unsigned int value = 4267;
        void binary_to_ascii(value);

        return 0;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
