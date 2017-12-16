module("luci.controller.bwmon", package.seeall)

function index()
	local page
	page = entry({"admin", "services", "bwmon"}, cbi("bwmon/bwmon"), "Bandwidth Monitoring", 70)
	page.dependent = true
end