#include <time.h>
#include <stdio.h>

int main()
{
	time_t t;
	t=time(0);

	printf("t = %d\n", t);

	return 0;
}
