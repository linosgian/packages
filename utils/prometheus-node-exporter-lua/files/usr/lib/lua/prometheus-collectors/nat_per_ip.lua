require("uci")

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

local function scrape()
  x = uci.cursor();
  hosts = {};
  x:foreach("dhcp", "host", function(s)
    hosts[s["ip"]] = s["name"];
  end)

  down = metric("node_nat_downlink_per_ip", "counter")
  up = metric("node_nat_uplink_per_ip","counter")
  total = metric("node_nat_total_per_ip","counter")
  for e in io.lines("/tmp/usage.db") do
    local f = split(e, ",");
    if (not string.find(f[1], "mac")) then
        local mac, ip, iface, bytes_in, bytes_out, bytes_total = f[1], f[2], f[3], f[4], f[5], f[6], f[7];

        local hostname = ip
        if hosts[ip] then
          hostname = hosts[ip]
        end
        local labels = { hostname = hostname, mac = mac, ip = ip, iface = iface}
        down(labels, bytes_in )
        up(labels, bytes_out )
        total(labels, bytes_total )
    end
  end
end

return { scrape = scrape }

