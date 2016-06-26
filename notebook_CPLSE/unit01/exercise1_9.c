// 将字符串中多个空格合并为一个空格
#include <stdio.h>

int main()
{
	int c;
	int val = 0;
	while ((c = getchar()) != EOF)
	{
		if (val == ' ' && c == ' ')
		{
			continue;
		}
		putchar(c);
		val = c;
	}

	return 0;
}
