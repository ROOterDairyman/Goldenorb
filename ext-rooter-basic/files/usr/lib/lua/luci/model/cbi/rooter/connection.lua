local utl = require "luci.util"

local maxmodem = luci.model.uci.cursor():get("modem", "general", "max")

m = Map("modem", translate("Modem Connection Information"), translate("Please fill out the entries below"))

m.on_after_commit = function(self)
	--luci.sys.call("/etc/modpwr")
end

--
-- Individual Modems
--

di = {}
ma = {}
mu = {}
mp = {}
mpi = {}
mau = {}
mf = {}
md = {}
ml = {}
mcc = {}
mnc = {}
mdns1 = {}
mdns2 = {}
mlog = {}
mlb = {}
matc = {}
mat = {}

for i=1,maxmodem do
	stri = string.format("%d", i)
	minfo = "minfo" .. stri
	di[i] = m:section(TypedSection, minfo, "Modem " .. stri .. " Information")
	ma[i] = di[i]:option(Value, "apn", "APN :"); 
	ma[i].rmempty = true;
--	ma[i].default = "modem" .. stri .. "apn"

	mu[i] = di[i]:option(Value, "user", "User Name :"); 
	mu[i].optional=false; 
	mu[i].rmempty = true;

	mp[i] = di[i]:option(Value, "passw", "Password :"); 
	mp[i].optional=false; 
	mp[i].rmempty = true;
	mp[i].password = true

	mpi[i] = di[i]:option(Value, "pincode", "PIN :"); 
	mpi[i].optional=false; 
	mpi[i].rmempty = true;

	mau[i] = di[i]:option(ListValue, "auth", "Authentication Protocol :")
	mau[i]:value("0", "None")
	mau[i]:value("1", "PAP")
	mau[i]:value("2", "CHAP")
	mau[i].default = "0"

	mf[i] = di[i]:option(ListValue, "ppp", "Force Modem to PPP Protocol :");
	mf[i]:value("0", "No")
	mf[i]:value("1", "Yes")
	mf[i].default=0

	md[i] = di[i]:option(Value, "delay", "Connection Delay in Seconds :"); 
	md[i].optional=false; 
	md[i].rmempty = false;
	md[i].default = 5
	md[i].datatype = "and(uinteger,min(1))"

	ml[i] = di[i]:option(ListValue, "lock", "Lock Connection to a Provider :");
	ml[i]:value("0", "No")
	ml[i]:value("1", "Yes")
	ml[i].default=0

	mcc[i] = di[i]:option(Value, "mcc", "Provider Country Code :");
	mcc[i].optional=false; 
	mcc[i].rmempty = true;
	mcc[i].datatype = "and(uinteger,min(1),max(999))"
	mcc[i]:depends("lock", "1")

	mnc[i] = di[i]:option(Value, "mnc", "Provider Network Code :");
	mnc[i].optional=false; 
	mnc[i].rmempty = true;
	mnc[i].datatype = "and(uinteger,min(1),max(999))"
	mnc[i]:depends("lock", "1")

	mdns1[i] = di[i]:option(Value, "dns1", "Custom DNS Server1 :"); 
	mdns1[i].rmempty = true;
	mdns1[i].optional=false;
	mdns1[i].datatype = "ipaddr"

	mdns2[i] = di[i]:option(Value, "dns2", "Custom DNS Server2 :"); 
	mdns2[i].rmempty = true;
	mdns2[i].optional=false;
	mdns2[i].datatype = "ipaddr"

	mlog[i] = di[i]:option(ListValue, "log", "Enable Connection Logging :");
	mlog[i]:value("0", "No")
	mlog[i]:value("1", "Yes")
	mlog[i].default=0

	if nixio.fs.access("/etc/config/mwan3") then
		mlb[i] = di[i]:option(ListValue, "lb", "Enable Load Balancing at Connection :");
		mlb[i]:value("0", "No")
		mlb[i]:value("1", "Yes")
		mlb[i].default=0
	end

	mat[i] = di[i]:option(ListValue, "at", "Enable Custom AT Startup Command at Connection :");
	mat[i]:value("0", "No")
	mat[i]:value("1", "Yes")
	mat[i].default=0

	matc[i] = di[i]:option(Value, "atc", "Custom AT Startup Command :");
	matc[i].optional=false;
	matc[i].rmempty = true;
	--matc[i]:depends("at", "1")

end

return m