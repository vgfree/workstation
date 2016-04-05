#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
	int opt;
	char *optstring = "a:b:c:d";

	while ((opt = getopt(argc, argv, optstring)) != -1)
	{
		printf("opt = %c\n", opt);	// 检查到某一参数时，函数返回被指定的 参数名称
		printf("optarg = %s\n", optarg);// 参数数值
		printf("optind = %d\n", optind);// 下一个将被处理到的 参数下标值 
		printf("argv[option - 1] = %s\n\n", argv[optind - 1]);
	}

	return 0;
}




