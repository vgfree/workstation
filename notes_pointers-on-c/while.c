#include <stdio.h>

int main()
{
        int x = 0;
        int b = 0;
        while(b += x, x += 1, x < 10)
                ;

        printf("%d %d\n", x, b);
        return 0;
}
