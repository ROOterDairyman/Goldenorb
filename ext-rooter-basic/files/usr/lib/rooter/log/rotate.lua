#!/usr/bin/lua

logfile = {}
infile = arg[1]
outfile = arg[2]

i=0
ifile = io.open(infile, "r")
if ifile == nil then
	return
end
repeat
	local line = ifile:read("*line")
	if line == nil then
		break
	end
	if string.len(line) > 1 then
		i = i + 1
		logfile[i] = line
	end
until 1==0
ifile:close()
if i < 50 then
	j = 1
else
	j = i - 49
end
ofile = io.open(outfile, "w")
for k=j,i do
	ofile:write(logfile[k] .. "\n")
end
ofile:close()