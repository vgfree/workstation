// 统计各字符串出现的频度

#include <stdio.h>

int main()
{
	int i, c, len;

	int ch[97];
	for (i = 0; i < 97; i++)
		ch[i] = 0;

	while((c = getchar()) != EOF) {
		if (c < 32 || c > 127)
			++ch[96];
		else
			++ch[c - 32];
	}


	for (i = 0; i < 96; i++) {
		printf("%c :", i + 32);
		for (len = 0; len < ch[i]; i++)
			printf("*");
		printf("\n");
	}

	printf("others :");
	for (i = 0; i < ch[96]; i++)
		printf("*");
	printf("\n");

	return 0;
}
