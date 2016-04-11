#include <stdio.h>

int
main(void)
{
        int i = 10;
        int j = 20;
        int const *p1 = &i;
        int * const p2 = &j;
        printf("p1 = %p\n", p1);
        printf("p2 = %p\n", p2);
        printf("p1 = %d\n", *p1);
        printf("p2 = %d\n", *p2);

        p1 = &j;
        *p2 = i;

        printf("p1 = %p\n", p1);
        printf("p2 = %p\n", p2);
        printf("p1 = %d\n", *p1);
        printf("p2 = %d\n", *p2);

        return 0;
}
