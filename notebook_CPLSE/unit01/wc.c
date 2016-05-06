#include <stdio.h>

main ()
{
	int c, f;
	for(f = 0; f <= 300; f += 20)
	{
		c = (5 * (f - 32)) / 9;
		printf("%d\t%d\n", f, c);
	}
}
