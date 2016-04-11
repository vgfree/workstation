#include <stdio.h>
#include <stdlib.h>

int
main(int argc, char *argv[])
{
        int year = atoi(argv[1]);

        int leap_year;

        if (year % 4 == 0)
        {
                if ((year % 100 == 0) && (year % 400 == 0))
                {
                        leap_year = 1;
                        printf("leap_year = %d\n", leap_year);
                }
                else
                {
                        leap_year = 0;
                        printf("leap_year = %d\n", leap_year);
                }
        }
        else
        {
                leap_year = 0;
                printf("leap_year = %d\n", leap_year);

        }

        return 0;
}

/*
 * 注意：1. main函数传参参数格式
 *
 * */
