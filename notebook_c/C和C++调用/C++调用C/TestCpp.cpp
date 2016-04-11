#include "stdio.h"
extern "C"
{
#include "TestC.h"
}

int main()
{
        printf("add = %d\n", add(2, 5));
        
        return 0;
}
