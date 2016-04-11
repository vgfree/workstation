<<<<<<< HEAD
/*
** Mystery function
**
**	The argument is a value in the range 0 through 100.
*/
#include <stdio.h>

void
mystery( int n )
{
	n += 5;
	n /= 10;
	printf( "%s\n", "**********" + 10 - n );
        // 当n = 2时，10 - 2 = 8，那么此时打印的 *　其实是从第９个开始打印，总计２个
}

int
main()
{
        int i;
        for (i = 0; i < 100; i++)
        {
                mystery(i);
        }

        return 0;
}
=======
/*
** Mystery function
**
**	The argument is a value in the range 0 through 100.
*/
#include <stdio.h>

void
mystery( int n )
{
	n += 5;
	n /= 10;
	printf( "%s\n", "**********" + 10 - n );
        // 当n = 2时，10 - 2 = 8，那么此时打印的 *　其实是从第９个开始打印，总计２个
}

int
main()
{
        int i;
        for (i = 0; i < 100; i++)
        {
                mystery(i);
        }

        return 0;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
