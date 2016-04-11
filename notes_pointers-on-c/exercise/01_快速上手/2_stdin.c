#include <stdio.h>

int
main()
{
        int ch;
        ch = fgetc(stdin);
        fputc(ch, stdout);

        return 0;
}
