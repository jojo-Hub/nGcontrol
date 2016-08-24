--- use to retrive connection details from an Huawei 3372h dongle
--  tested to work on debian 8 and openWRT CC
--
--  Version 1.2.1
--
--  Requirements: lua and luasocket
--    $ sudo apt-get install lua luasocket         #debian
--    # opkg update && opkg install lua luasocket  #openWRT
--
--  Set link to proper location or copy the lua source
--    $ sudo ln -s huaweiLib.lua /usr/share/lua/5.2/ #debian
--    $ scp huaweiLib.lua root@router:/usr/lib/lua/  #openWRT
--
--  Include and call with
--    local huaweiLib = require("huaweiLib")
--    dongle = huaweiLib.queryStatus("192.168.1.1")
--  Afterwards, you can access the members with
--    dongle.member
--
--  Valid members are:
--    connectionStatNum numerical value of current connection status
--    connectionStat    translated form of current connection status
--    strength          signal strength between 0 (no) .and 5 (max)
--    networkTypeNum    numerical network type e.g. GSM, LTE, UMTS...
--    networkType       translated network type
--    wanIPAddress      IP in mobile network, it's NOT its public IP
--    cellID            ID of connected cell         
--    rsrq              RSRQ value
--    rsrp              RSRP value
--    rssi              RSSI value
--    sinr              SINR value
--    providerState     provider's country
--    providerName      provider's name
--    totalDownload     total of downloaded since online, in Bytes
--    totalUpload       total of uploaded since online, in Bytes
--  You can extend the members by adding more evaluated queries
--  to the return of queryDongle()
--
--  Thanks to trick77 (https://github.com/trick77/huawei-hilink-status)
--  whoose work was initial to create this library.

local huaweiLib = {}

-- helper function to parse XML
local function xmlParse (string, tag)
  local pattern = "<"..tag..">(.-)</"..tag..">"
  return string.match(string, pattern)
end

-- helper function to parse connection status
local function statusParse(stat)

    if     stat == '901' then return "Connected"
    elseif stat == '902' then return "Disconnected"
    elseif stat == '904' then return "Connection failed or disabled"
    elseif stat == '900' then return "Connecting"
    elseif stat == '903' then return "Disconnecting"

    elseif stat == '201' then return "Connection failed, bandwidth exceeded"

    elseif(stat ==  '7' or stat == '11' or 
           stat == '14' or stat == '37')
      then return "Network access not allowed"

    elseif(stat == '12' or stat == '13')
      then return "Connection failed, roaming not allowed"

    elseif(stat ==  '2' or stat ==  '3' or
           stat ==  '5' or stat ==  '8' or
           stat == '20' or stat == '21' or
           stat == '23' or stat == '27' or
           stat == '28' or stat == '29' or
           stat == '30' or stat == '31' or
           stat == '32' or stat == '33')
      then return 'Connection failed, the profile is invalid'

    else return "Error, reason unknown (no matching status code)."
    end
end

-- helper function to parse network type
local function networkTypeParse(numStr)

  if (numStr == nil) then return "n/a" 
  end

  local num = tonumber(numStr)
  
  if (0 <= num and num <= 19) then
    local lookuptable = {
            "No Service", "GSM", "GPRS (2.5G)", "EDGE (2.75G)",
            "WCDMA (3G)", "HSDPA (3G)", "HSUPA (3G)", "HSPA (3G)",
            "TD-SCDMA (3G)", "HSPA+ (4G)", "EV-DO rev. 0",
            "EV-DO rev. A", "EV-DO rev. B", "1xRTT", "UMB", "1xEVDV",
            "3xRTT","HSPA+ 64QAM", "HSPA+ MIMO", "LTE (4G)"
          }
    return lookuptable[num+1]
  elseif num ==  41 then return "UMTS (3G)"
  elseif num ==  44 then return "HSPA (3G)"
  elseif num ==  45 then return "HSPA+ (3G)"
  elseif num ==  46 then return "DC-HSPA+ (3G)"
  elseif num ==  64 then return "HSPA (3G)"
  elseif num ==  65 then return "HSPA+ (3G)"
  elseif num == 101 then return "LTE (4G)"
  else return "n/a"
  end

end

-- helper to send a general query to IP/path, SesTok needed for getting
-- values, SesTok is obtained by sendQuery(IP, "/api/webserver/SesTokInfo")
-- and has to be split into SesInfo and TokInfo with xmlParse afterwards.
--
-- If request is not provided, a regular GET is made, POST otherwise.
-- The POST-request will beprefixed with an XML-command so that only
-- the actual request has to be provided.
local function sendQuery (IP, path, SesTok, request)
  local payload = require("socket.http")
  local ltn12 = require("ltn12")
  local header = {}
  local result_table = {}
  local URL = "http://"..IP..path
  local _method = nil

  if (request == nil) then
    _method = "GET"
    request = ""
  else
    _method = "POST"
    request = "<?xml version='1.0' encoding='utf-8' ?>"..request
  end


  if ( SesTok == nil) then
    header = {
               ["Content-Type"] = "text/xml",
               ["USER-AGENT"] = "uPNP/1.0"
             }
  else
    header = {
               ["Content-Type"] = "text/xml",
               ["USER-AGENT"] = "uPNP/1.0",
               ["Cookie"] = SesTok[1],
               ["__RequestVerificationToken"] = SesTok[2],
               ["content-length"] = string.len(request)
             }
  end

  payload.request{
    url = URL,
    method = _method,
    headers = header,
    source = ltn12.source.string(request),
    sink = ltn12.sink.table(result_table)
  }

  return table.concat(result_table)

end

-- *******************************
--       start of APIs
-- *******************************


-- function to test if route to IP address exists
function huaweiLib.getDefaultGateways()
  local gateways = {}
  local pipe = io.popen'route -n|grep "UG"|grep -v "UGH"|cut -f 10 -d " "'
  for line in pipe:lines() do gateways[line] = true end
  pipe:close()

  return gateways
end 


-- function to get the status from an huawei dongle with IP Address IP
function huaweiLib.queryStatus(IPAddr)

  SesTokInfo = sendQuery(IPAddr, "/api/webserver/SesTokInfo")

  SesTok = {}
  SesTok[1] = xmlParse(SesTokInfo, "SesInfo")
  SesTok[2] = xmlParse(SesTokInfo, "TokInfo")

  -- get current status, signal, provider and traffic information
  status = sendQuery(IPAddr, "/api/monitoring/status", SesTok)
  signal = sendQuery(IPAddr, "/api/device/signal", SesTok)
  provider = sendQuery(IPAddr, "/api/net/current-plmn", SesTok)
  traffic = sendQuery(IPAddr, "/api/monitoring/traffic-statistics", SesTok)

  -- split information in different values and return them, for
  -- the *Num values we need local placeholders since we use them
  -- as argument for ther parser functions later
  local connectionStatNum = xmlParse(status, "ConnectionStatus")
  local networkTypeNum = xmlParse(status, "CurrentNetworkType")

  return {
    connectionStatNum = connectionStatNum,
    connectionStat    = statusParse(connectionStatNum),
    strength          = xmlParse(status, "SignalIcon"),
    networkTypeNum    = networkTypeNum,
    networkType       = networkTypeParse(networkTypeNum),
    wanIPAddress      = xmlParse(status, "WanIPAddress"),

    cellID = xmlParse(signal, "cell_id"),
    rsrq   = xmlParse(signal, "rsrq"),
    rsrp   = xmlParse(signal, "rsrp"),
    rssi   = xmlParse(signal, "rssi"),
    sinr   = xmlParse(signal, "sinr"),

    providerState = xmlParse(provider, "State"),
    providerName  = xmlParse(provider, "FullName"),

    totalDownload = xmlParse(traffic, "TotalDownload"),
    totalUpload   = xmlParse(traffic, "TotalUpload"),
  }

end

return huaweiLib
