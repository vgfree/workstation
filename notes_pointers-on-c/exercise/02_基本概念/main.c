#include "negate.h"
#include "increment.h"

int
main(void)
{
        printf("%d \t %d \t %d \n", increment(10), increment(0), increment(-10));
        printf("%d \t %d \t %d \n", negate(10), negate(0), negate(-10));

        return 0;
}


/*
 * gcc -c main.c interment.c negate.c
 * gcc -o main *.o
 */
