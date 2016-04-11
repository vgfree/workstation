#include <stdio.h>

int main(int argc, char const* argv[])
{
        FILE *fp = fopen("./a", "r");
        FILE *fp1 = fopen("./b", "w");
        int c;

        while (c = fgetc(fp)) {
                if (c != EOF)
                {
                        fputc(c, fp1);
                }
                else {
                        break;
                }
        }

        fclose(fp);
        fclose(fp1);

        return 0;
}
