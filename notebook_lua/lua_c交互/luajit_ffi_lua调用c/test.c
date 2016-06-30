#include <stdio.h>
#include </usr/include/luajit-2.0/luajit.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

typedef struct foo {
	int a;
	int b;
} foo_t;


extern int test(int a);
extern int dofoo(foo_t *f, int n);

int test(int a) {
	printf("a = %d\n", a);
	return 0;
}

int dofoo(foo_t *f, int n) {
	foo_t foo = *f;
	printf("dofoo\n");
	printf("foo.a = %d, foo.b = %d\n", foo.a, foo.b);
	foo.a = 100;
	foo.b = 200;

	*f = foo;
	return 0;
}

int main()
{
	lua_State *L;
	L = luaL_newstate();
	if (L == NULL) {
		printf("L is null\n");
		return -1;
	}

	luaL_openlibs(L);
	luaL_loadfile(L, "./lua1.lua");
	lua_pcall(L, 0, 0, 0);
	lua_close(L);

	return 0;
}
