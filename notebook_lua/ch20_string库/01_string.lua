s = "hello world"
print(string.len(s))

print(string.rep("a", 20))

print(string.upper("abcd123"))

print(string.lower("ABCD123"))

print(string.sub(s, 3, -3))

print(string.char(97))

print(string.byte('abc', -1))
print(string.byte('abc', -2))

--print(string.format("pi = %.4f", PI))

d = 5
m = 11
y = 1990
print(string.format( "%02d/%02d/%04d", d, m, y ))

tag, title = "h1", "a title"
print(string.format( "<%s>%s<%s>", tag, title, tag ))
