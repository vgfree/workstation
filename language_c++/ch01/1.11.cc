#include <iostream>
int main()
{
        int i = 0;
        int v1 = 0, v2 = 0;
        std::cout << "Enter two numbers" << std::endl;
        std::cin >> v1 >> v2;
        i = v1;
        if (v1 <= v2)
        {
                while (v1 <= i && i <= v2)
                {
                        std::cout << i << std::endl;
                        ++i;
                }
        }
        else
        {
                while (v2 <= i && i <= v1)
                {
                        std::cout << i << std::endl;
                        --i;
                }                    
        }
        return 0;
}
