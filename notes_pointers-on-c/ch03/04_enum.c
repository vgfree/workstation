#include <stdio.h>

int main()
{
        enum Week {
                Mon,
                Tue = 2,
                Wed,
                Thu,
                Fri,
                Sat,
                Sun = 0
        };

        printf("Mon = %d, Sat = %d, Sun = %d\n", Mon, Sat, Sun);

        return 0;
}
