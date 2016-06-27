#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
	printf("请选择需要的操作: \n");
	printf("1. 定时关机\n");
	printf("2. 立即关机\n");
	printf("3. 重新启动\n");
	printf("4. 退出操作\n");

	char cmd[20] = "shutdown -t ";
	int time;
	int c;

	scanf("%d", &c);
	switch (c)
	{
		case 1:
			printf("请输入关机时间, 单位为s :\n");
			scanf("%d", &time);
			system( strcat(cmd, (const char *)&time) );
			break;
		case 2:
			system("shutdown");
			break;
		case 3:
			system("shutdown -r");
			break;
		case 4:
			break;
		default:
			printf("error \n");
	}

	return 0;
}
