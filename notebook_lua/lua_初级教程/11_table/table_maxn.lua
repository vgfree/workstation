function table_maxn(t)
    local mn = 0
    for k, v in pairs(t) do
        if mn < k then
            mn = k
        end
    end
    return mn
end
tbl = {[1] = "a", [2] = "b", [3] = "c", [26] = "z"}
print("tbl 长度 ", #tbl) -- # 看样子只是计算有效长度， 26和前面之间不连续，所以只计算前面三个
print("tbl 最大值 ", table_maxn(tbl))
