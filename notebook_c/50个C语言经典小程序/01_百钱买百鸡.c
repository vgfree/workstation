#include <stdio.h>

int main()
{
	int x, y, z;
	int i = 0;

	for (x = 0; x < 20; x++)
	{
		for (y = 0; y < 34; y++)
		{
			for (z = 0; z < 300; z++)
			{
				if (5 * x + 3 * y + z / 3 == 100 && x + y + z == 100 && z % 3 == 0)
				{
					printf("方案 %d: ", ++i);
					printf("x = %2d\t y = %2d\t z = %2d\n", x, y, z);
				}
			}
		}
	}

	return 0;
}
