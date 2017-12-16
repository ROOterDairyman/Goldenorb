module("luci.controller.admin.modem", package.seeall)

function index() 
	entry({"admin", "modem"}, firstchild(), "Modem", 35).dependent=false
	entry({"admin", "modem", "cinfo"}, cbi("rooter/connection", {autoapply=true}), "Connection Info", 1)
	entry({"admin", "modem", "conmon"}, cbi("rooter/connmonitor"), "Connection Monitoring", 20)
	entry({"admin", "modem", "nets"}, template("rooter/net_status"), "Network Status", 30)
	entry({"admin", "modem", "debug"}, template("rooter/debug"), "Debug Information", 50)
	entry({"admin", "modem", "cust"}, cbi("rooter/customize"), "Custom Modem Ports", 55)
	entry({"admin", "modem", "log"}, template("rooter/log"), "Connection Log", 60)
	entry({"admin", "modem", "misc"}, template("rooter/misc"), "Miscellaneous", 40)

	entry({"admin", "modem", "get_csq"}, call("action_get_csq"))
	entry({"admin", "modem", "change_port"}, call("action_change_port"))
	entry({"admin", "modem", "change_mode"}, call("action_change_mode"))
	entry({"admin", "modem", "change_modem"}, call("action_change_modem"))
	entry({"admin", "modem", "change_modemdn"}, call("action_change_modemdn"))
	entry({"admin", "modem", "change_misc"}, call("action_change_misc"))
	entry({"admin", "modem", "change_miscdn"}, call("action_change_miscdn"))
	entry({"admin", "modem", "get_log"}, call("action_get_log"))
	entry({"admin", "modem", "check_misc"}, call("action_check_misc"))
	entry({"admin", "modem", "pwrtoggle"}, call("action_pwrtoggle"))
	entry({"admin", "modem", "disconnect"}, call("action_disconnect"))
	entry({"admin", "modem", "connect"}, call("action_connect"))
	entry({"admin", "modem", "get_atlog"}, call("action_get_atlog"))
	entry({"admin", "modem", "send_atcmd"}, call("action_send_atcmd"))
	entry({"admin", "modem", "change_rate"}, call("action_change_rate"))
	entry({"admin", "modem", "change_phone"}, call("action_change_phone"))
	entry({"admin", "modem", "clear_log"}, call("action_clear_log"))
	entry({"admin", "modem", "externalip"}, call("action_externalip"))
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function action_get_atlog()
	local file
	local rv ={}

	file = io.open("/tmp/atlog", "r")
	if file ~= nil then
		local tmp = file:read("*all")
		rv["log"] = tmp
		file:close()
	else
		rv["log"] = "No entries in log file"
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_get_log()
	local file
	local rv ={}

	file = io.open("/usr/lib/rooter/log/connect.log", "r")
	if file ~= nil then
		local tmp = file:read("*all")
		rv["log"] = tmp
		file:close()
	else
		rv["log"] = "No entries in log file"
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_disconnect()
	local set = luci.http.formvalue("set")
	os.execute("/usr/lib/rooter/connect/disconnect.sh")
end

function action_connect()
	local set = luci.http.formvalue("set")
	miscnum = luci.model.uci.cursor():get("modem", "general", "miscnum")
	os.execute("/tmp/links/reconnect" .. miscnum .. " " .. miscnum)
end

function action_pwrtoggle()
	local set = luci.http.formvalue("set")
	os.execute("/usr/lib/rooter/pwrtoggle.sh " .. set)
end

function action_send_atcmd()
	local rv ={}
	modnum = luci.model.uci.cursor():get("modem", "general", "modemnum")
	local file
	local set = luci.http.formvalue("set")
	fixed = string.gsub(set, "\"", "~")
	os.execute("/usr/lib/rooter/luci/atcmd.sh \'" .. fixed .. "\'")

	result = "/tmp/result" .. modnum .. ".at"
	file = io.open(result, "r")
	if file ~= nil then
		rv["result"] = file:read("*all")
		file:close()
		os.execute("/usr/lib/rooter/luci/luaops.sh delete /tmp/result" .. modnum .. ".at")
	else
		rv["result"] = " "
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_check_misc()
	local rv ={}
	local file
	local active
	local connect

	miscnum = luci.model.uci.cursor():get("modem", "general", "miscnum")
	conn = "Modem #" .. miscnum
	rv["conntype"] = conn
	empty = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "empty")
	if empty == "1" then
		active = "0"
		rv["netmode"] = "-"
	else
		active = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "active")
		if active == "1" then
			connect = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "connected")
			if connect == "0" then
				active = "1"
			else
				active = "2"
			end
		end
		netmode = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "netmode")
		rv["netmode"] = netmode
	end
	rv["active"] = active
	file = io.open("/tmp/gpiopin", "r")
	if file == nil then
		rv.gpio = "0"
	else
		rv.gpio = "1"
		line = file:read("*line")
		line = file:read("*line")
		if line ~= nil then
			rv.gpio = "2"
		end
		file:close()
	end
	file = io.open("/sys/bus/usb/drivers/usb/usb1", "r")
	if file == nil then
		rv["usb"] = "0"
	else
		io.close(file)
		rv["usb"] = "1"
	end
	file = io.open("/sys/bus/usb/drivers/usb/usb2", "r")
	if file ~= nill then
		io.close(file)
		rv["usb"] = "2"
	end
	proto = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "proto")
	rv["proto"] = proto

	celltype = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "celltype")
	rv["celltype"] = celltype
	cmode = luci.model.uci.cursor():get("modem", "modem" .. miscnum, "cmode")
	if cmode == "0" then
		rv["netmode"] = "10"
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function lshift(x, by)
  return x * 2 ^ by
end

function rshift(x, by)
  return math.floor(x / 2 ^ by)
end

function action_change_mode()
	local set = tonumber(luci.http.formvalue("set"))
	local modemtype = rshift(set, 4)
	local temp = lshift(modemtype, 4)
	local netmode = set - temp
	os.execute("/usr/lib/rooter/luci/modechge.sh " .. modemtype .. " " .. netmode)
end

function action_change_port()
	local set = tonumber(luci.http.formvalue("set"))
	if set ~= nil and set > 0 then
		if set == 1 then
			os.execute("/usr/lib/rooter/luci/portchge.sh dwn")
		else
			os.execute("/usr/lib/rooter/luci/portchge.sh up")
		end
	end
end

function action_change_misc()
	os.execute("/usr/lib/rooter/luci/modemchge.sh misc 1")
end

function action_change_miscdn()
	os.execute("/usr/lib/rooter/luci/modemchge.sh misc 0")
end

function action_change_modem()
	os.execute("/usr/lib/rooter/luci/modemchge.sh modem 1")
end

function action_change_modemdn()
	os.execute("/usr/lib/rooter/luci/modemchge.sh modem 0")
end

function action_get_csq()
	modnum = luci.model.uci.cursor():get("modem", "general", "modemnum")
	local file
	stat = "/tmp/status" .. modnum .. ".file"
	file = io.open(stat, "r")

	local rv ={}

	rv["port"] = file:read("*line")
	rv["csq"] = file:read("*line")
	rv["per"] = file:read("*line")
	rv["rssi"] = file:read("*line")
	rv["modem"] = file:read("*line")
	rv["cops"] = file:read("*line")
	rv["mode"] = file:read("*line")
	rv["lac"] = file:read("*line")
	rv["lacn"] = file:read("*line")
	rv["cid"] = file:read("*line")
	rv["cidn"] = file:read("*line")
	rv["mcc"] = file:read("*line")
	rv["mnc"] = file:read("*line")
	rv["rnc"] = file:read("*line")
	rv["rncn"] = file:read("*line")
	rv["down"] = file:read("*line")
	rv["up"] = file:read("*line")
	rv["ecio"] = file:read("*line")
	rv["rscp"] = file:read("*line")
	rv["ecio1"] = file:read("*line")
	rv["rscp1"] = file:read("*line")
	rv["netmode"] = file:read("*line")
	rv["cell"] = file:read("*line")
	rv["modtype"] = file:read("*line")
	rv["conntype"] = file:read("*line")
	rv["channel"] = file:read("*line")
	rv["phone"] = file:read("*line")
	file:read("*line")
	rv["lband"] = file:read("*line")

	file:close()

	cmode = luci.model.uci.cursor():get("modem", "modem" .. modnum, "cmode")
	if cmode == "0" then
		rv["netmode"] = "10"
	end	

	rssi = rv["rssi"]
	ecio = rv["ecio"]
	rscp = rv["rscp"]
	ecio1 = rv["ecio1"]
	rscp1 = rv["rscp1"]

	if ecio == nil then
		ecio = "-"
	end
	if ecio1 == nil then
		ecio1 = "-"
	end
	if rscp == nil then
		rscp = "-"
	end
	if rscp1 == nil then
		rscp1 = "-"
	end

	if ecio ~= "-" then
		rv["ecio"] = ecio .. " dB"
	end
	if rscp ~= "-" then
		rv["rscp"] = rscp .. " dBm"
	end
	if ecio1 ~= " " then
		rv["ecio1"] = " (" .. ecio1 .. " dB)"
	end
	if rscp1 ~= " " then
		rv["rscp1"] = " (" .. rscp1 .. " dBm)"
	end

	if not nixio.fs.access("/etc/netspeed") then
		rv["crate"] = "Fast (updated every 10 seconds)"
	else
		rv["crate"] = "Slow (updated every 60 seconds)"
	end

	stat = "/tmp/msimdata" .. modnum
	file = io.open(stat, "r")
	if file == nil then
		rv["modid"] = " "
		rv["imei"] = " "
		rv["imsi"] = " "
		rv["iccid"] = " "
		rv["host"] = "0"
	else
		rv["modid"] = file:read("*line")
		rv["imei"] = file:read("*line")
		rv["imsi"] = file:read("*line")
		rv["iccid"] = file:read("*line")
		rv["host"] = file:read("*line")
		file:close()
	end
	stat = "/tmp/msimnum" .. modnum
	file = io.open(stat, "r")
	if file == nil then
		rv["phone"] = "-"
		rv["phonen"] = " "
	else
		rv["phone"] = file:read("*line")
		rv["phonen"] = file:read("*line")
		file:close()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_change_rate()
	local set = luci.http.formvalue("set")
	if set == "1" then
		os.execute("rm -f /etc/netspeed")
	else
		os.execute("echo \"0\" > /etc/netspeed")
	end
end

function action_change_phone()
	local set = luci.http.formvalue("set")
	s, e = string.find(set, "|")
	pno = string.sub(set, 1, s-1)
	pnon = string.sub(set, e+1)
	modnum = luci.model.uci.cursor():get("modem", "general", "modemnum")
	os.execute("/usr/lib/rooter/common/phone.sh " .. modnum .. " " .. pno .. " \"" .. pnon .. "\"")
end

function action_clear_log()
        local file
        file = io.open("/usr/lib/rooter/log/connect.log", "w")
        file:close()
        os.execute("/usr/lib/rooter/log/logger 'Connection Log Cleared by User'")
end

function action_externalip()
	local rv ={}

	os.execute("rm -f /tmp/ipip; wget -O /tmp/ipip http://ipecho.net/plain > /dev/null 2>&1")
	file = io.open("/tmp/ipip", "r")
	if file == nil then
		rv["extip"] = "Not Available"
	else
		rv["extip"] = file:read("*line")
		if rv["extip"] == nil then
			rv["extip"] = "Not Available"
		end
		file:close()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
