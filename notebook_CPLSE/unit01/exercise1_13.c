// 统计文本中单词长度直方图
#include <stdio.h>

int main()
{
	int len, i, c;
	int length[10];

	for (i = 0; i < 10; i++)
		length[i] = 0;

	len = 0;
	while ((c = getchar()) != EOF)
		if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
			++len;
		}
		else {
			if (len > 9)
				++length[0];
			else if ( len > 0 && len <= 9 )
				++length[len];

			len = 0;
		}

	for (i = 1; i < 10; i++) {
		printf("长度 = %2d :", i);
		for (len = 0; len < length[i]; len++)
			printf("*");
		printf("\n");
	}

	printf("长度 > 10 :");
	for (len = 0; len < length[0]; len++)
		printf("*");
	printf("\n");

	return 0;
}
