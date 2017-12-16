#!/usr/bin/lua

modem = arg[1]
numb = arg[2]
echo = 0

datalist = {}
celllist = {}

datalist[1] = "320u"
celllist[1] = 2
datalist[2] = "330u"
celllist[2] = 2
datalist[3] = "e3276"
celllist[3] = 3
datalist[4] = "e398"
celllist[4] = 3
datalist[5] = "e389"
celllist[5] = 3
datalist[6] = "e392"
celllist[6] = 3
datalist[7] = "e397"
celllist[7] = 3
datalist[8] = "e8278"
celllist[8] = 3
datalist[9] = "mf820"
celllist[9] = 3
datalist[10] = "mf821"
celllist[10] = 3
datalist[11] = "k5005"
celllist[11] = 3
datalist[12] = "k5007"
celllist[12] = 3
datalist[13] = "l800"
celllist[13] = 3
datalist[14] = "e398"
celllist[14] = 3
datalist[15] = "mf880"
celllist[15] = 3
datalist[16] = "e3272"
celllist[16] = 3
datalist[17] = "e3372"
celllist[17] = 3
datalist[18] = "lte"
celllist[18] = 3
datalist[19] = "340u"
celllist[19] = 2
datalist[20] = "mf91d"
celllist[20] = 3
datalist[21] = "mf825a"
celllist[21] = 3
datalist[22] = "mf826"
celllist[22] = 3
datalist[23] = "313u"
celllist[23] = 2
datalist[24] = "341u"
celllist[24] = 2
datalist[25] = "em74"
celllist[25] = 2
datalist[26] = "mc74"
celllist[26] = 2

printf = function(s,...)
	if echo == 0 then
		io.write(s:format(...))
	else
		ss = s:format(...)
		os.execute("/usr/lib/rooter/logprint.sh " .. ss)
	end
end

found = 1
index = 1
line = datalist[index]
data = string.lower(modem)

while line ~= nil do
	s, e = string.find(data, line)
	if s ~= nil then
		found = celllist[index]
		break
	end
	index = index + 1
	line = datalist[index]
end

file = io.open("/tmp/celltype" .. numb, "w")
cell = string.format("%s%s%s%s", "CELL", "=\"", found, "\"")
file:write(cell.. "\n")
file:close()