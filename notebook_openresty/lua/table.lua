local corp = {
	web		= 'www.google.com',
	telephone	= '18516548998',
	staff		= {'louis', 'miku', 'shana'},
	10086,
	10010,
	[10] = 360,
	['city'] = 'hangzhou'
}

print(corp.web)
print(corp['web'])
print(corp[1])
print(corp[2])
print(corp.city)
print(corp.staff[1])
print(corp[10])
