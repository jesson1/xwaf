local timeHelper = require "xwaf.timeHelper"
local _M = {}

function _M.exitWithMsg( msg, status )
    ngx.header.content_type = "text/html"
    ngx.status = status
    ngx.say(msg)
    ngx.exit(ngx.status)
end

function _M.publishToRedisAndExit(redis, client, msg, status)
	redis:publishLog(client)
	_M.exitWithMsg(msg, status)
end

function _M.switch( redis, name)
	return redis:getOptionStatusByName(name)
end

function _M.checkPostOrGetArgsV1(self, args, ruleSet )
	local data
	for _, rule in pairs(ruleSet) do
		for key, val in pairs(args) do
			if type(val) == "boolean" then
			-- 参数没有按照标准web格式传递 key1=value1&key2=value2
				data = key
			elseif type(val) == "table" then
				data = ""
			-- 参数中存在数组 key1[]=value1&key1[]=value2
				for k, v in pairs(val) do
					if type(v) ~= "boolean" then
						data = data .. v
					end
				end
			else
			-- 参数标准 key1=value1&key2=value2且没有数组
				data = val
			end
			m = ngx.re.match(data, rule, "isjo")
			if m then
				return false, rule, m[0]
			end
		end
	end
	return true, "", ""
end

function _M.split(self, str, reps )
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end

function _M.getFile(self, file_name)
    local f = assert(io.open(file_name, 'r'))
    local string = f:read("*all")
    f:close()
    return string
end

function _M.getUriArgs( self )
	local result = {}
	local list = ngx.re.match(ngx.var.request_uri, "([^\\?]+)\\?{0,1}([\\s\\S]*)")
	if list == nil then
		return result
	end
	if list[2] == "" then
		return result
	else
		local uriStr = list[2]
		-- self:formatRowHttpStrV1(uriStr, result, 1, {})
		self:formatRowHttpStrV2(uriStr, result)
		return result
	end
end

function _M.getBodyArgs( self )
	local result = {}
	print("start read_body: "..timeHelper.current_time_millis())
	ngx.req.read_body()
	print("end read_body: "..timeHelper.current_time_millis())
	postStr = ngx.req.get_body_data()
	if nil == postStr then
		-- 超过nginx缓冲区大小的body数据会被存储到临时文件中
        local file_name = ngx.req.get_body_file()
        if file_name then
        	print("start read tmp file: "..timeHelper.current_time_millis())
            postStr = self:getFile(file_name)
            print("end read tmp file: "..timeHelper.current_time_millis())
        end
    end
	if postStr then
		-- self:formatRowHttpStrV1(postStr, result, 1, {})
		print("start formatRowHttpStrV2 : ".. timeHelper.current_time_millis())
		self:formatRowHttpStrV2(postStr, result)
		print("end formatRowHttpStrV2 : ".. timeHelper.current_time_millis())
	end
	return result
end

function _M.checkPostOrGetArgsV2(self, args, ruleSet )
	for _, rule in pairs(ruleSet) do
		for key, val in pairs(args) do
			if type(val) == "table" then
				data = table.concat(val, ",")
			else
				data = val
			end
			m = ngx.re.match(data, rule, "isjo")
			if m then
				return false, rule, m[0]
			end
		end
	end
	return true, "", ""
end

function _M.formatRowHttpStrV1( self, str, result, i, match )
	match[i] = ngx.re.match(str, "([^&]*)&{0,1}([\\s\\S]*)", "isjo")
	if match[i][1] ~= "" and match[i][2] ~= "" then
		self:formatRowHttpStr(match[i][1] , result, i+1, match)
		self:formatRowHttpStr(match[i][2], result, i+1, match)
	else
		if match[i][1] ~= "" then
			self:format(match[i][1], result)
		end
		if match[i][2] ~= "" then
			self:format(match[i][2], result)
		end
	end
end

function _M.formatRowHttpStrV2(self, str, result)
	list = self:split(str, "&")
	for _, item in pairs(list) do
		self:format(item, result)
	end
end

function _M.format( self, str, result )
	m = ngx.re.match(str, "^([^=]+)={0,1}([\\s\\S]*)$", "isjo")
	if m == nil then
		return
	end
	if m[2] == "" then
		key = self:urlDecode(m[1])
		value = true
	else
		key = self:urlDecode( m[1] )
		value = self:urlDecode( m[2] )
	end
	same = result[ key ]
	if same then
		if type(same) == "string" or type(same) == "boolean" then
			result[ key ] = { same, value}
		elseif type(same) == "table" then
			table.insert(same, value)
		end
	else
		result[ key ] = value
	end
end




function _M.urlEncode(self, s)
    s = string.gsub(s, "([^%w%.%- ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return string.gsub(s, " ", "+")
end
function _M.urlDecode(self, s)
    s = string.gsub(s, "%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

return _M