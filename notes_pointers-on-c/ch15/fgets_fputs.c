#include <stdio.h>
int main(int argc, char const* argv[])
{
        char str[64];
        FILE *fp = fopen("./a", "r");
        FILE *fp1 = fopen("./b", "w");

        while(NULL != fgets(str, 64, fp))
        {
                fputs(str, fp1);
        }

        fclose(fp);
        fclose(fp1);

        return 0;
}
