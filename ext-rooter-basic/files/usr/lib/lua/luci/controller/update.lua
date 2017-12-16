module("luci.controller.update", package.seeall)

function index()
	local page

	page = entry({"admin", "status", "update"}, template("rooter/update"), _("ROOter Firmware Update"))
	page = entry({"admin", "status", "get_ver"}, call("action_get_ver"))
	page = entry({"admin", "status", "get_change"}, call("action_get_change"))
	page.dependent = true
end

function read_log()
	local file = io.open("/tmp/change.file", "r")
	if file ~= nil then
		ret = file:read("*all")
		file:close()
	else
		ret = "<p>*************************</p><p>No Change Log Found</p><p>*************************</p>"
	end
	return ret
end

function action_get_ver()
	local rv ={}

	rv["current"] = luci.model.uci.cursor():get("modem", "Version", "ver")
	rv["last"] = luci.model.uci.cursor():get("modem", "Version", "last")
	if rv["last"] == nil then
		rv["last"] = "Not Checked"
	end

	rv["log"] = read_log()
	rv["status"] = " "

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_get_change()
	local rv ={}

	local err = os.execute("/usr/lib/rooter/luci/getlog.sh")

	rv["current"] = luci.model.uci.cursor():get("modem", "Version", "ver")
	rv["last"] = luci.model.uci.cursor():get("modem", "Version", "last")
	if rv["last"] == nil then
		rv["last"] = "Not Checked"
	end

	rv["log"] = read_log()
	if err == 0 then
		rv["status"] = " "
	else
		rv["status"] = "An Error occured while fetching the Change Log"
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
