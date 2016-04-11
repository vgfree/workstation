#include <stdio.h>

int main()
{
        int i = 10;
        {
                printf("%d\n", i);
                int i = 1;
                printf("%d\n", i);
        }

        {
                int i = 20;
                printf("%d\n", i);
        }
        int i = 30;
}
