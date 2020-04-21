local common = require "xwaf.common"
local cjson = require "cjson"
local config = require "xwaf.config"
local timeHelper = require "xwaf.timeHelper"

local _M = {
	checkName = "body"
}

local mt = {__index = _M}


function _M.new(self, redis)
	return setmetatable({redis=redis}, mt)
end

function _M.check( self, client)
	if common.switch(self.redis, self.checkName) then
		print("start checkUploadFile: "..timeHelper.current_time_millis())
		result = self:checkUploadFile(client)
		print("checkUploadFile end: "..timeHelper.current_time_millis())
		if result == false then
			print("start checkBodyArgs: "..timeHelper.current_time_millis())
			self:checkBodyArgs(client)	
			print("checkBodyArgs end: "..timeHelper.current_time_millis())
		end

	end
end



function _M.checkBodyArgs( self, client )
	print("start read redis : "..timeHelper.current_time_millis())
	ruleSet = self.redis:getSetByName("post")
	print("end read redis: "..timeHelper.current_time_millis())
	bodyArgs = common:getBodyArgs()
	client.bodyArgs = bodyArgs
	print("start checkPostOrGetArgsV1: "..timeHelper.current_time_millis())
	pass, rule, target = common:checkPostOrGetArgsV1(bodyArgs, ruleSet)
	print("end checkPostOrGetArgsV1: "..timeHelper.current_time_millis())
	if pass == false then
		client.pass = false
		table.insert(client.attackInfo, {type="body",
		 message="the bodyArgs of this request is invalid", rule=rule, target=target})
		return common.publishToRedisAndExit(self.redis, client, 
			"your request is dangerous", ngx.HTTP_FORBIDDEN)
	end
end

function _M.checkUploadFile( self, client )
	local boundary = self:getBoundary()
	if boundary == nil then
		return false
	end

	local len = string.len
    local sock, err = ngx.req.socket()
    if not sock then
		return false
    end
    ngx.req.init_body()
    sock:settimeout(0)
    local content_length = nil
	content_length=tonumber(ngx.req.get_headers()['content-length'])
	local chunk_size = 4096
    if content_length < chunk_size then
		chunk_size = content_length
    end
    local size = 0
    local m
    while size < content_length do
		local data, err, partial = sock:receive(chunk_size)
		data = data or partial
		if not data then
			return false
		end
		--文件名在post的body中 格式： Content-Disposition: form-data; name="fileField"; filename="xxx.xxx"
		if m == nil then
			m = ngx.re.match(data,[[Content-Disposition: form-data;(.+)filename="(.+?)(\.)(.*)"]],'ijo')
			if m then
				client.uploadFileName = m[2]..m[3]..m[4]
				self:checkFileExt(m[4], client)
			end
		end
		self:checkFileContent(data, client)	

		ngx.req.append_body(data)
		size = size + len(data)


		local less = content_length - size
		if less < chunk_size then
			chunk_size = less
		end
 	end
	ngx.req.finish_body()
	return true
end

function _M.checkFileExt(self, ext, client)
	blackFileExtSet = self.redis:getSetByName(config.blackFileExt)
	ext = string.lower(ext)
	if ext then
        for _, rule in pairs(blackFileExtSet) do
        	m = ngx.re.match(ext,rule,"isjo")
            if m then
	        	client.pass = false
				table.insert(client.attackInfo, {type="body",
					message="the fileExt of this request is invalid", rule=rule, target=m[0] })
				return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
            end
        end
    end
end


function _M.checkFileContent( self, data, client )
	ruleSet = self.redis:getSetByName("post")
	print(data)
	for _, rule in pairs(ruleSet) do
		m = ngx.re.match(data, rule, "isjo")
		if m then
			client.pass = false
			table.insert(client.attackInfo, {type="body",
				message="the content of this upload file is invalid", rule=rule, target=m[0] })
			return common.publishToRedisAndExit(self.redis, client, 
				"your request is dangerous", ngx.HTTP_FORBIDDEN)
		end
	end
end


function _M.getBoundary(self)
    local header = ngx.req.get_headers()["content-type"]
    if not header then
        return nil
    end

    if type(header) == "table" then
        header = header[1]
    end

    local m = string.match(header, ";%s*boundary=\"([^\"]+)\"")
    if m then
        return m
    end

    local n = string.match(header, ";%s*boundary=([^\",;]+)")
    return n
end

return _M