local function scrape()
        local pkts, bytes, from, to;
        local elem = {};
        local result = io.popen("iptables -xvnL RRDIPT_FORWARD -t mangle");
        local output = result:read('*all');
        result:close();

        down = metric("node_nat_downlink_per_ip", "counter")
        up = metric("node_nat_uplink_per_ip", "counter")

        for line in output:gmatch("([^\n]*)\n?") do
                if string.find(line, "RETURN") then
                        cols = space_split(line);
                        pkts, bytes, from, to = cols[1], cols[2], cols[8], cols[9];
                        if from == "0.0.0.0/0" then
                                if (not elem[to]) then
                                        elem[to] = {};
                                end
                                elem[to]["down"] = bytes;
                        else
                                if (not elem[from]) then
                                        elem[from] = {};
                                end
                                elem[from]["up"] = bytes;
                        end
                end
        end
        local hostname;
        local total_down = 0;
        local total_up = 0;
        for ip, val in pairs(elem) do
                local labels;
                local result = io.popen("nslookup "..ip.." localhost");
                local output = result:read('*all');
                result:close();

                hostname = ip;
                if string.match(output, 'name =') then
                        hostname = string.match(output, "name = (.-)\n");
                end
                down({ hostname = hostname }, val["down"]);
                up({ hostname = hostname }, val["up"]);
                total_down = total_down + val["down"];
                total_up = total_up + val["up"];
        end
        down({ hostname = "total" }, total_down);
        up({ hostname = "total" }, total_up);

end

return { scrape = scrape }

