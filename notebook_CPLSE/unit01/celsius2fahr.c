// 摄氏转华氏

#include <stdio.h>

int main()
{
	float fahr, celsius;
	int lower, upper, step;

	lower = 0;
	upper = 300;
	step = 20;

	celsius = lower;
	printf("a program to convert fahr to celsius \n");
	while (fahr <= upper)
	{
		fahr = 9.0 * celsius / 5.0 - 32.0;
		printf("%3.0f\t%6.1f\n", celsius, fahr);
		celsius += step;
	}
}
