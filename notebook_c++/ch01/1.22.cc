// 需要思考的是当只有一组数据传入时及初始岁时item, itemAll各成员的初始值为0 
// 怎样才能把二者都初始化呢?
#include <iostream>
#include "Sales_item.h"

int main()
{
        Sales_item item, itemAll;
        if (std::cin >> item)
        {
                while (std::cin >> itemAll)
                        item += itemAll;
        }
        std::cout << item << std::endl;
        
        return 0;        
}
