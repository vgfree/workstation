// 统计输入的字符数目
#include <stdio.h>

int main()
{
	long nc;

	for (nc = 0; getchar() != EOF; ++nc)
		;
	printf("nc = %ld\n", nc);

	return 0;
}
