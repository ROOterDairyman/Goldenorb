-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2008 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.openvpn", package.seeall)

function index()
	entry( {"admin", "services", "openvpn"}, cbi("openvpn"), _("OpenVPN") )
	entry( {"admin", "services", "openvpn", "basic"},    cbi("openvpn-basic"),    nil ).leaf = true
	entry( {"admin", "services", "openvpn", "advanced"}, cbi("openvpn-advanced"), nil ).leaf = true
	
	entry({"admin", "services", "rsastatus"}, call("action_status"))
	entry({"admin", "services", "rsagenerate"}, call("action_generate"))
	entry({"admin", "services", "rsastop"}, call("action_stop"))
end

function action_status()
	local rv = {}
	
	file = io.open("/tmp/easyrsa", "r")
	if file ~= nil then
		rv["status"] = file:read("*line")
		file:close()	
	else
		rv["status"] = "0"
	end
	
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_generate()
	os.execute("/usr/lib/easyrsa/generate.sh &")
end

function action_stop()
	os.execute("/usr/lib/easyrsa/stop.sh")
end

