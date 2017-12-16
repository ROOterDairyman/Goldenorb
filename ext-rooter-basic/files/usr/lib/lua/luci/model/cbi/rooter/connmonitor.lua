local utl = require "luci.util"

local maxmodem = luci.model.uci.cursor():get("modem", "general", "max")

m = Map("modem", translate("Modem Connection Monitoring"), translate("Use Pinging to keep the Modem Connection Working"))

m.on_after_commit = function(self)
	--luci.sys.call("/etc/monitor")
	--luci.sys.call("/etc/pingchk")
end

d = {}
c1 = {}
reliability = {}
interval = {}
timeout = {}
cb2 = {}
down = {}
up = {}
count = {}
packetsize = {}

for i=1,maxmodem do
	stri = string.format("%d", i)
	pinfo = "pinfo" .. stri
	d[i] = m:section(TypedSection, pinfo, "Modem " .. stri .. " Ping Details")

	c1[i] = d[i]:option(ListValue, "alive", "MONITOR WITH OPTIONAL RECONNECT :");
	c1[i]:value("0", "Disabled")
	c1[i]:value("1", "Enabled")
	c1[i]:value("2", "Enabled with Router Reboot")
	c1[i]:value("3", "Enabled with Modem Reconnect")
	c1[i]:value("4", "Enabled with Power Toggle or Modem Reconnect")
	c1[i].default=0

	reliability[i] = d[i]:option(Value, "reliability", translate("Tracking reliability"),
		translate("Acceptable values: 1-100. This many Tracking IP addresses must respond for the link to be deemed up"))
	reliability[i].datatype = "range(1, 100)"
	reliability[i].default = "1"
	reliability[i]:depends("alive", "1")
	reliability[i]:depends("alive", "2")
	reliability[i]:depends("alive", "3")
	reliability[i]:depends("alive", "4")

	count[i] = d[i]:option(ListValue, "count", translate("Ping count"))
	count[i].default = "1"
	count[i]:value("1")
	count[i]:value("2")
	count[i]:value("3")
	count[i]:value("4")
	count[i]:value("5")
	count[i]:depends("alive", "1")
	count[i]:depends("alive", "2")
	count[i]:depends("alive", "3")
	count[i]:depends("alive", "4")

	interval[i] = d[i]:option(ListValue, "pingtime", translate("Ping interval"),
		translate("Amount of time between tracking tests"))
	interval[i].default = "5"
	interval[i]:value("5", translate("5 seconds"))
	interval[i]:value("10", translate("10 seconds"))
	interval[i]:value("20", translate("20 seconds"))
	interval[i]:value("30", translate("30 seconds"))
	interval[i]:value("60", translate("1 minute"))
	interval[i]:value("180", translate("3 minute"))
	interval[i]:value("300", translate("5 minutes"))
	interval[i]:value("600", translate("10 minutes"))
	interval[i]:value("900", translate("15 minutes"))
	interval[i]:value("1800", translate("30 minutes"))
	interval[i]:value("3600", translate("1 hour"))
	interval[i]:depends("alive", "1")
	interval[i]:depends("alive", "2")
	interval[i]:depends("alive", "3")
	interval[i]:depends("alive", "4")

	timeout[i] = d[i]:option(ListValue, "pingwait", translate("Ping timeout"))
	timeout[i].default = "2"
	timeout[i]:value("1", translate("1 second"))
	timeout[i]:value("2", translate("2 seconds"))
	timeout[i]:value("3", translate("3 seconds"))
	timeout[i]:value("4", translate("4 seconds"))
	timeout[i]:value("5", translate("5 seconds"))
	timeout[i]:value("6", translate("6 seconds"))
	timeout[i]:value("7", translate("7 seconds"))
	timeout[i]:value("8", translate("8 seconds"))
	timeout[i]:value("9", translate("9 seconds"))
	timeout[i]:value("10", translate("10 seconds"))
	timeout[i]:depends("alive", "1")
	timeout[i]:depends("alive", "2")
	timeout[i]:depends("alive", "3")
	timeout[i]:depends("alive", "4")

	packetsize[i] = d[i]:option(Value, "packetsize", translate("Ping packet size in bytes"),
		translate("Acceptable values: 4-56. Number of data bytes to send in ping packets. This may have to be adjusted for certain ISPs"))
	packetsize[i].datatype = "range(4, 56)"
	packetsize[i].default = "56"
	packetsize[i]:depends("alive", "1")
	packetsize[i]:depends("alive", "2")
	packetsize[i]:depends("alive", "3")
	packetsize[i]:depends("alive", "4")

	down[i] = d[i]:option(ListValue, "down", translate("Interface down"),
		translate("Interface will be deemed down after this many failed ping tests"))
	down[i].default = "3"
	down[i]:value("1")
	down[i]:value("2")
	down[i]:value("3")
	down[i]:value("4")
	down[i]:value("5")
	down[i]:value("6")
	down[i]:value("7")
	down[i]:value("8")
	down[i]:value("9")
	down[i]:value("10")
	down[i]:depends("alive", "1")
	down[i]:depends("alive", "2")
	down[i]:depends("alive", "3")
	down[i]:depends("alive", "4")

	up[i] = d[i]:option(ListValue, "up", translate("Interface up"),
		translate("Downed interface will be deemed up after this many successful ping tests"))
	up[i].default = "3"
	up[i]:value("1")
	up[i]:value("2")
	up[i]:value("3")
	up[i]:value("4")
	up[i]:value("5")
	up[i]:value("6")
	up[i]:value("7")
	up[i]:value("8")
	up[i]:value("9")
	up[i]:value("10")
	up[i]:depends("alive", "1")
	up[i]:depends("alive", "2")
	up[i]:depends("alive", "3")
	up[i]:depends("alive", "4")

	cb2[i] = d[i]:option(DynamicList, "trackip", translate("Tracking IP"),
		translate("This IP address will be pinged to dermine if the link is up or down."))
	cb2[i].datatype = "ipaddr"
	cb2[i].default="8.8.8.8"
	cb2[i]:depends("alive", "1")
	cb2[i]:depends("alive", "2")
	cb2[i]:depends("alive", "3")
	cb2[i]:depends("alive", "4")
	cb2[i].optional=false;

end

return m

