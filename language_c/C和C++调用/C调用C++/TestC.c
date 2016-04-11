#include "stdio.h"

extern int add_cpp(int a, int b);
int main()
{
        printf("add_cpp = %d\n", add_cpp(2, 5));

        return 0;
}
