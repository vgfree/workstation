#include <stdio.h>
#include "add.h"
#include "multi.h"

int main()
{
	int i = add(10, 20);
	int j = multi(10, 20);

	printf("i = %d, j = %d\n", i, j);

	return 0;
}
