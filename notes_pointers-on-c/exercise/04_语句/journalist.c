#include <stdio.h>
#include <stdlib.h>
int
main(int argc, char *argv[])
{
        printf("please input your number: \n");
        char ch = getchar
        int i = atoi(argv[1]);

        while(ch = getchar())
        {
                switch(i)
                {
                        case 1:
                                printf("who\n");
                                break;
                        case 2:
                                printf("what\n");
                                break;
                        case 3:
                                printf("when\n");
                                break;
                        case 4:
                                printf("where\n");
                                break;
                        case 5:
                                printf("why\n");
                                break;
                        default:
                                printf("i don't know\n");
                                break;
                }
        }
        return 0;
}


