/*
 * C语言动态数组的实现：数组长度随数组元素改变，不会溢出，不会浪费资源
 * 讲数入的数组输出
*/

#include <stdio.h>
#include <stdlib.h>

int main()
{
	int length;
	int *str;
	int i;

	printf("Please input the length: ");
	scanf("%d", &length);

	// calloc 返回值为数组, 且初始值为0
	str = (int *)calloc(length, sizeof(int));

	for (i = 0; i < length; i++)
	{
		scanf("%d", &str[i]);
	}

	for (i = 0; i < length; i++)
	{
		printf("%d\t", str[i]);
	}

	free(str);
	str = NULL;
	printf("\n");

	return 0;
}
