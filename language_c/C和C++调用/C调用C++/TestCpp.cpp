#include "TestClass.h"

extern "C" int add_cpp(int a, int b);
int add_cpp(int a, int b)
{
        HJH hjh;
        return hjh.add(a, b);
}
