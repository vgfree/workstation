#include <stdio.h>
#include <stdlib.h>

int add(int x, int y)
{
        return x + y;
}
typedef struct function{
        int (*add)(int x, int y);
}fun;

int main()
{
        fun function;
        int x = 1;
        int y = 2;

        printf("%d\n", function.add(x, y));

        return 0;
}

