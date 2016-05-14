#include <stdio.h>                                                              
int main()                                                                      
{                                                                               
        int i;                                                                  
        double sum = 0;                                                            
                                                                                
        for (i = 0; i <= 10000000; i++)      // i++表示每执行一次i的值+1             
        {                                                                                                                                                                 
	                sum = sum + i;                                                  
	        }                                                                       
                                                                                
        printf("sum = %lf \n", sum);                                             
                                                                                
        return 0;                                                               
}           
