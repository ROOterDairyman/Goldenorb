module("luci.controller.guestwifi", package.seeall)

function index()
	local page

	page = entry({"admin", "network", "guestwifi"}, cbi("guestwifi", {hidesavebtn=true, hideresetbtn=true}), "Guest Wifi", 22)
	page.dependent = true
end
