s = "abcd{efg}"

print(string.sub(s, string.find(s, "{.+}")))
