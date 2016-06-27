/*
 电脑-玩家    石头4	剪刀7	布10
 石头0	       4	7	10
 剪刀1	       5	8	11
 布  2	       6	9	12

*/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main()
{
	char gamer;
	int computer;
	int result;

	while (1)
	{
		system("clear"); // 程序开始是清屏
		printf("这是一个猜拳小游戏, 请输入你要出的拳: \n");
		printf("A : 石头\tB : 剪刀\tC : 布\tD : 不玩了\n");

		scanf("%c%*c", &gamer); // 从缓冲区多读一个字符(回车符), 但并不赋值(丢弃)
		switch(gamer)
		{
			case 'A':
				gamer = 4;
				break;
			case 'B':
				gamer = 7;
				break;
			case 'C':
				gamer = 10;
				break;
			case 'D':
				return 0;
			default:
				printf("输入错误, 现在退出...\n");
				getchar();
				continue;
		}

		// 一系统时间为种子产生随机数
		srand( (unsigned)time(NULL) );
		computer = rand() % 3;

		result = computer + gamer;

		printf("你的出拳是: ");
		switch(gamer)
		{
			case 4:
				printf("石头\n");
				break;
			case 7:
				printf("剪刀\n");
				break;
			case 10:
				printf("布\n");
				break;
		}

		printf("电脑的出拳是: ");
		switch(computer)
		{
			case 0:
				printf("石头\n");
				break;
			case 1:
				printf("剪刀\n");
				break;
			case 2:
				printf("布\n");
				break;
		}

		if (result == 7 || result == 11 || result == 9)
		{
			printf("电脑胜!\n");
		}
		else if (result == 10 || result == 5 || result == 6)
		{
			 printf("你胜!\n");
		}
		else
		{
			printf("平局!\n");
		}

		getchar(); // 把缓冲区的回车符清掉
		system("clear");
	}

	return 0;
}
