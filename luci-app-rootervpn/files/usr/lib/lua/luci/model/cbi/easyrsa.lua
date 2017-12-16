local utl = require "luci.util"

m = Map("easyrsa", "OpenVPN Certificates and Keys",
	translate("Create the certificates and keys for OpenVPN Server and Client"))

m.on_after_commit = function(self)

end

gw = m:section(TypedSection, "easyrsa", translate("Certificate and Key Data"), translate("The following data is used to generate unique, random certs and keys."))
gw.anonymous = true

country = gw:option(Value, "country", translate("Country Name :"), translate("2 letter country abbreviation")); 
country.optional=false; 
country.rmempty = true;
country.default="CA"
country.datatype = "rangelength(2, 2)"

city = gw:option(Value, "city", translate("City Name :")); 
city.optional=false; 
city.rmempty = true;
city.default="Abbotsford"
city.datatype = "minlength(2)"

organ = gw:option(Value, "organ", translate("Organization Name :"), translate("name will appear on certs and keys")); 
organ.optional=false; 
organ.rmempty = true;
organ.default="ROOter"
organ.datatype = "minlength(2)"

days = gw:option(Value, "days", translate("Days to certify for :"), translate("number of days certs and keys are valid")); 
days.optional=false; 
days.rmempty = true;
days.default="3650"
days.datatype = "min(1)"

dmy = gw:option(DummyValue, "_dmy", translate(" "))

m:section(SimpleSection).template = "easyrsa/easyrsa"

return m
