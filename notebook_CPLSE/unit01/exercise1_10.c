// 将字符中指定字符替换
#include <stdio.h>

int main()
{
	char c;
	while ((c = getchar()) != EOF)
	{
		/*
		switch (c)
		{
			case '\t':
				printf("\\t");
			case '\b':
				printf("\b");
			case '\\':
				printf("\\");
			default:
				putchar(c);
		}
		*/
		if ( c == '\t' )
		{
			printf("\\t");
		}
		else if (c == '\b')
		{
			printf("\\b");
		}
		else if (c == '\\')
		{
			printf("\\\\");
		}
		else
		{
			putchar(c);
		}
	}

	return 0;
}
