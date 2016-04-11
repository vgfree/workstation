#include <stdio.h>

int main()
{
        char const *p = "hello";
        p = "world";

        char * const p1 = "hello";
//        p1 = "world";

        printf("p = %s, p1 = %s\n", p + 1, p1 + 1);

        return 0;
}
