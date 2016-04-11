#include <stdio.h>
#include <stdlib.h>
int filelength(FILE *fp);
char *readfile(char *path);

int main(void)
{
        struct a m;
        struct b n;

        FILE *fp;
        char *string;
        string=readfile("./test.txt");
        printf("读入完毕\n按任意键释放内存资源\n");
        //printf("%s\n",string);
        system("pause");
        return 0;
}
char *readfile(char *path)
{
        FILE *fp;
        int length;
        char *ch;
        if((fp=fopen(path,"r"))==NULL)
        {
                printf("open file %s error.\n",path);
                exit(0);
        }
        length=filelength(fp);
        ch=(char *)malloc(length);
        fread(ch,length,1,fp);
        *(ch+length-1)='\0';
        return ch;
}
int filelength(FILE *fp)
{
        int num;
        fseek(fp,0,SEEK_END);
        num=ftell(fp);
        fseek(fp,0,SEEK_SET);
        return num;
}
