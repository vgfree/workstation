#include <iostream>

int main()
{
        int currVal = 0, val = 0;
        while (std::cin >> currVal)
        {
                int cnt = 1;
                while (std::cin >> val)
                {
                        if (currVal == val)
                        {
                                ++cnt;
                        }
                        else
                        {
                                std::cout << currVal << " " << cnt << std::endl;
                                currVal = val;
                                cnt = 1;
                        }
                }
                std::cout << currVal << " " << cnt << std::endl;
        }
        return 0;
}
