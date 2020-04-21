function dump_tostring(t)
    local string_format = string.format;
    local table_insert = table.insert;
    local sp = " ";
    local list = {};
    local function addline(str)
        table_insert(list, str);
    end

    local function do_tostring(tt, l, ln)
        local tp = type(tt);
        if (tp == "table") then
            l = l + 1;
            if (l - 1 == 0) then
                addline("{");
            end
            for k, v in pairs(tt) do
                local pp = type(v);
                if (pp == "table") then
                    addline(string_format("%"..l.."s[%s]={",sp,k));
                    do_tostring(v, l + 1);
                    addline(string_format("%"..l.."s},",sp));
                else
                    addline(string_format("%"..l.."s[%s]=%s,",sp,k,tostring(v)));
                end

            end
            if (l - 1 == 0) then
                addline("}");
            end
        else
            addline(string_format("%"..l.."s=%s,",sp,k,tostring(tt)));
        end

    end

    do_tostring(t, 0);

    return table.concat(list, "\n");
end