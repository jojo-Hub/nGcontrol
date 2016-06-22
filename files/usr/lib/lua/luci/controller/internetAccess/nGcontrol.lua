module("luci.controller.internetAccess.nGcontrol", package.seeall)

function index()
     entry({"admin", "internetAccess"}, firstchild(), "Internet Access", 60).dependent=false
     entry({"admin", "internetAccess", "status"}, template("internetAccess/index2"), _("Status and Control"), 1)

     entry({"admin", "internetAccess", "statusOf"}, call("_statusOf"), nil).leaf = true
     entry({"admin", "internetAccess", "statusChange"}, call("_statusChange"), nil).leaf = true

end

function _statusChange(action, interface)

	os.execute("logger -t mwan3 'user requested to "..action.." UMTS"..interface.."'")

        if action == 'Disable' then
          os.execute("/root/scripts/dongleOff "..interface)
        elseif action == 'Enable' then
          os.execute("/root/scripts/dongleOn "..interface)
          os.execute("/root/scripts/mwan/dongleReset "..interface)
        else   
          os.execute("/root/scripts/mwan/dongleReset "..interface)
        end
end


function _statusOf(iface)

  local mArray = {}
  local IP = "192.168."..iface..".1"

  require("uci")
  local huaweiLib = require("huaweiLib")
  local netm = require("luci.model.network").init() -- to get the interfaces' uptime

  x = uci.cursor()

  -- check whether iface is enabled
  local interfaceEnabled = (x:get("mwan3", "UMTS"..iface, "enabled") == "1")
  if not interfaceEnabled then
    mArray.Enabled = 0
  else
    mArray.Enabled = 1

    -- check whether iface can be reached
    local gateways = huaweiLib.getDefaultGateways()
    if not gateways[IP] then
      mArray.Route = 0
    else
      -- we can read info of iface since route exists to
      mArray.Route = 1
      mArray.Status = huaweiLib.queryStatus(IP)
      -- and add uptimeinfo (in secondes, will be parsed from javaScript)
      local netm = require("luci.model.network").init()
      local net = netm:get_network("UMTS"..iface)
      mArray.Uptime = tonumber(net:uptime())
      -- and add ResetAttempts
      mArray.retryAttempts = x:get("mwan3", "UMTS"..iface, "retryAttempt")
      mArray.retryMax = x:get("mwan3", "config", "retryMax")

    end
  end

  -- send gathered info via json
  luci.http.prepare_content("application/json")
  luci.http.write_json(mArray)


end
