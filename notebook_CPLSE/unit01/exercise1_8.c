#include <stdio.h>
// 很奇怪为什么制表符默认后面有个\n, 使用if 语句就不会错
int main()
{
	int ns, nt, nl, c;
	ns = 0;
	nt = 0;
	nl = 0;

	while ((c = getchar()) != EOF)
	{
		/*
		   if (c == ' ')
		   {
		   ++ns;
		   }
		   else if (c == '\t')
		   {
		   ++nt;
		   }
		   else if (c == '\n')
		   {
		   ++nl;
		   }
		   */
		printf("c = %c\n", c);
		switch (c)
		{
			case ' ':
				++ns;
			case '\t':
				++nt;
			case '\n':
				++nl;
			default:
				continue;
		}
	}

	printf("ns = %d, nt = %d, nl = %d\n", ns, nt, nl);

	return 0;
}
