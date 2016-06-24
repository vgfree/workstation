#include <stdio.h>

int main()
{
	char buf[10];
	sprintf(buf, "hello %s", "world");
	printf("%s\n", buf);

	return 0;
}
