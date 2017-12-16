#!/usr/bin/lua

mfile = "/tmp/sysinfo/model"
echo = 1
model = {}
gpio = {}
gpio2 = {}

pin = nil
pin2 = nil

model[1] = "703n"
gpio[1] = 8
model[2] = "3020"
gpio[2] = 8
model[3] = "11u"
gpio[3] = 8
model[4] = "3040"
gpio[4] = 18
model[5] = "3220"
gpio[5] = 6
model[6] = "3420"
gpio[6] = 6
model[7] = "wdr3500"
gpio[7] = 12
model[8] = "wdr3600"
gpio[8] = 22
gpio2[8] = 21
model[9] = "wdr4300"
gpio[9] = 22
gpio2[9] = 21
model[10] = "wdr4310"
gpio[10] = 22
gpio2[10] = 21
model[11] = "842"
gpio[11] = 6
model[12] = "13u"
gpio[12] = 18
model[13] = "710n"
gpio[13] = 8
model[14] = "10u"
gpio[14] = 18
model[15] = "oolite"
gpio[15] = 18
model[16] = "720"
gpio[16] = 8
model[17] = "1043"
gpio[17] = 21
model[18] = "4530"
gpio[18] = 22
model[19] = "archer"
gpio[19] = 22
gpio2[19] = 21
model[20] = "ar150"
gpio[20] = 6
model[21] = "domino"
gpio[21] = 6
model[22] = "300a"
gpio[22] = 0
model[23] = "300n"
gpio[23] = 7
model[24] = "wdr4900"
gpio[24] = 10

numodel = 24

local file = io.open(mfile, "r")
if file == nil then
	return
end

line = file:read("*line")
file:close()
line = line:lower()

for i=1,numodel do
	start, ends = line:find(model[i])
	if start ~= nil then
		if model[i] == "3420" then
			start, ends = line:find("v1")
			if start ~= nil then
				pin = gpio[i]
				pin2 = nil
			else
				pin = 4
				pin2 = nil
			end
		else
			if model[i] == "3220" then
				start, ends = line:find("v1")
				if start ~= nil then
					pin = gpio[i]
					pin2 = nil
				else
					pin = 8
					pin2 = nil
				end
			else
				if model[i] == "1043" then
					start, ends = line:find("v2")
					if start ~= nil then
						pin = gpio[i]
						pin2 = nil
					end
				else
					pin = gpio[i]
					pin2 = gpio2[i]
				end
			end
		end

		break
	end
end

if pin ~= nil then
	local tfile = io.open("/tmp/gpiopin", "w")
	if pin2 ~= nil then
		tfile:write("GPIOPIN=\"", pin, "\"\n")
		tfile:write("GPIOPIN2=\"", pin2, "\"")
	else
		tfile:write("GPIOPIN=\"", pin, "\"")
	end
	tfile:close()
end
