#include <stdio.h>
#include <string.h>

int main()
{
	char str[2];
	strcpy(&str[0], "000");
	strcpy(&str[1], "111");

	int i;
	for (i = 0; i < 2; i++)
	{
		printf("%s \n", str[i]);
	}

	return 0;
}
