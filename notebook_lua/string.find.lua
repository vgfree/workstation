pair = "Host: 192.168.71.84:2223"
firstidx, lastidx, key, value = string.find(pair, "(%a+):%s*(.+)")
print(key, value)

