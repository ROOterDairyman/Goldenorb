-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

local fs  = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local testfullps = luci.sys.exec("ps --help 2>&1 | grep BusyBox") --check which ps do we have
local psstring = (string.len(testfullps)>0) and  "ps w" or  "ps axfw" --set command we use to get pid

local m = Map("openvpn", translate("OpenVPN"), translate("Set up a VPN Tunnel on your Router"))

m.on_after_commit = function(self)
	luci.sys.call("/usr/lib/easyrsa/firewall.sh")
	luci.sys.call("/usr/lib/easyrsa/dns.sh")
end

local_web="<p>&nbsp;<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\" " .. "OpenVPN Recipes" .. " \" onclick=\"window.open('http://www.ofmodemsandmen.com/recipes.html')\"/></p>"

local s = m:section( TypedSection, "openvpn", translate("OpenVPN instances"), translate("Below is a list of configured OpenVPN instances and their current state") )
s.template = "cbi/tblsection"
s.template_addremove = "openvpn/cbi-select-input-add"
s.addremove = true
s.add_select_options = { }
s.extedit = luci.dispatcher.build_url(
	"admin", "services", "openvpn", "basic", "%s"
)

uci:load("rooter_recipes")
uci:foreach( "rooter_recipes", "openvpn_recipe",
	function(section)
		s.add_select_options[section['.name']] =
			section['_description'] or section['.name']
	end
)

function s.getPID(section) -- Universal function which returns valid pid # or nil
	local pid = sys.exec("%s | grep -w %s | grep openvpn | grep -v grep | awk '{print $1}'" % { psstring,section} )
	if pid and #pid > 0 and tonumber(pid) ~= nil then
		return tonumber(pid)
	else
		return nil
	end
end

function s.parse(self, section)
	local recipe = luci.http.formvalue(
		luci.cbi.CREATE_PREFIX .. self.config .. "." ..
		self.sectiontype .. ".select"
	)

	if recipe and not s.add_select_options[recipe] then
		self.invalid_cts = true
	else
		TypedSection.parse( self, section )
	end
end

function s.create(self, name)
	local recipe = luci.http.formvalue(
		luci.cbi.CREATE_PREFIX .. self.config .. "." ..
		self.sectiontype .. ".select"
	)
	name = luci.http.formvalue(
		luci.cbi.CREATE_PREFIX .. self.config .. "." ..
		self.sectiontype .. ".text"
	)
	if string.len(name)>3 and not name:match("[^a-zA-Z0-9_]") then
		uci:section(
			"openvpn", "openvpn", name,
			uci:get_all( "rooter_recipes", recipe )
		)

		uci:delete("openvpn", name, "_role")
		uci:delete("openvpn", name, "_description")
		uci:save("openvpn")

		luci.http.redirect( self.extedit:format(name) )
	else
		self.invalid_cts = true
	end
end


s:option( Flag, "enabled", translate("Enabled") )
s:option( Flag, "bootstart", translate("Start on Bootup") )

local active = s:option( DummyValue, "_active", translate("Started") )
function active.cfgvalue(self, section)
	local pid = s.getPID(section)
	if pid ~= nil then
		return (sys.process.signal(pid, 0))
			and translatef("yes (%i)", pid)
			or  translate("no")
	end
	return translate("no")
end

local updown = s:option( Button, "_updown", translate("Start/Stop") )
updown._state = false
updown.redirect = luci.dispatcher.build_url(
	"admin", "services", "openvpn"
)
function updown.cbid(self, section)
	local pid = s.getPID(section)
	self._state = pid ~= nil and sys.process.signal(pid, 0)
	self.option = self._state and "stop" or "start"
	return AbstractValue.cbid(self, section)
end
function updown.cfgvalue(self, section)
	self.title = self._state and "stop" or "start"
	self.inputstyle = self._state and "reset" or "reload"
end
function updown.write(self, section, value)
	if self.option == "stop" then
		local pid = s.getPID(section)
		if pid ~= nil then
			sys.process.signal(pid,15)
			while pid ~= nil do
				pid = s.getPID(section)
			end
		end
	else
		luci.sys.call("/etc/init.d/openvpn start %s" % section)
	end
	luci.http.redirect( self.redirect )
end


local port = s:option( DummyValue, "port", translate("Port") )
function port.cfgvalue(self, section)
	local val = AbstractValue.cfgvalue(self, section)
	return val or "1194"
end

local proto = s:option( DummyValue, "proto", translate("Protocol") )
function proto.cfgvalue(self, section)
	local val = AbstractValue.cfgvalue(self, section)
	return val or "udp"
end

--xw = m:section(TypedSection, "settings", translate(" "), translate("Click the button below for a guide on using the Recipes for creating OpenVPN Instances."))
--xw.anonymous = true
--btn = xw:option(DummyValue, "_dmy", translate(" ") .. local_web);

gw = m:section(TypedSection, "settings", translate("Advanced Options"))
gw.anonymous = true
gw:tab("default", translate("Custom Firewall Settings"))
gw:tab("dns", translate("Custom DNS Settings"))
gw:tab("key", translate("Key and Certificate Generation"))

this_tab = "default"

gw:taboption(this_tab, Flag, "vpn2lan", translate("Forward Client VPN to LAN"), translate("(Client) Allow clients behind the VPN server to connect to computers within your LAN") )
gw:taboption(this_tab, Flag, "vpns2lan", translate("Forward Server VPN to LAN"), translate("(Server) Allow clients behind the VPN server to connect to computers within your LAN") )
gw:taboption(this_tab, Flag, "vpn2wan", translate("Forward Server VPN to WAN"), translate("(Server) Allow clients to connect to the internet (WAN) through the tunnel") )

this_tab = "dns"

gw:taboption(this_tab, Flag, "lanopendns", translate("LAN DNS using OpenDNS"), translate("Fixed DNS on LAN interface using OpenDNS") )
gw:taboption(this_tab, Flag, "langoogle", translate("LAN DNS using Google"), translate("Fixed DNS on LAN interface using Google") )
gw:taboption(this_tab, Flag, "wanopendns", translate("WAN DNS using OpenDNS"), translate("Fixed DNS on WAN interface using OpenDNS") )
gw:taboption(this_tab, Flag, "wangoogle", translate("WAN DNS using Google"), translate("Fixed DNS on WAN interface using Google") )

this_tab = "key"

country = gw:taboption(this_tab, Value, "country", translate("Country Name :"), translate("2 letter country abbreviation")); 
country.optional=false; 
country.rmempty = true;
country.default="CA"
country.datatype = "rangelength(2, 2)"

city = gw:taboption(this_tab, Value, "city", translate("City Name :")); 
city.optional=false; 
city.rmempty = true;
city.default="Abbotsford"
city.datatype = "minlength(2)"

organ = gw:taboption(this_tab, Value, "organ", translate("Organization Name :"), translate("name will appear on certs and keys")); 
organ.optional=false; 
organ.rmempty = true;
organ.default="ROOter"
organ.datatype = "minlength(2)"

comm = gw:taboption(this_tab, Value, "comm", translate("Common Name :"), translate("(Optional) Common Name of Organization")); 
comm.optional=true; 
comm.rmempty = true;

unit = gw:taboption(this_tab, Value, "unit", translate("Section Name :"), translate("(Optional) Name of Section")); 
unit.optional=true; 
unit.rmempty = true;

unstruc = gw:taboption(this_tab, Value, "unstruc", translate("Optional Organization Name :"), translate("(Optional) Another Name for Organization")); 
unstruc.optional=true; 
unstruc.rmempty = true;

email = gw:taboption(this_tab, Value, "email", translate("Email Address :"), translate("(Optional) Email Address")); 
unit.optional=true; 
unit.rmempty = true;

days = gw:taboption(this_tab, Value, "days", translate("Days to certify for :"), translate("number of days certs and keys are valid")); 
days.optional=false; 
days.rmempty = true;
days.default="3650"
days.datatype = "min(1)"

sx = gw:taboption(this_tab, Value, "_dmy1", translate(" "))
sx.template = "easyrsa/easyrsa"


return m
