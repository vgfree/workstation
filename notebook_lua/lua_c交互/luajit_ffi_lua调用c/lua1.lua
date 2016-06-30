local ffi = require("ffi")

ffi.cdef[[
	int printf(const char *fmt, ...);
	typedef struct foo {int a, b;} foo_t;
	int dofoo(foo_t *f, int n);
	int test(int a);
]]

ffi.c.printf("hello %s!\n", "world")

local foo = ffi.new("foo_t")
foo.a = 100
foo.b = 200
ffi.c.printf("foo.a = %d\n", ffi.new("int", foo.a))
ffi.c.printf("foo.b = %d\n", ffi.new("int", foo.b))

ffi.c.testddf(new("int", 200))
