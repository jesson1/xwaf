local redis = require "resty.redis"
local config = require "xwaf.config"
local common = require "xwaf.common"
local json = require "cjson"

local _M = {}
local mt = {__index = _M}

function _M.new( self )
	local red = redis:new()
	red:set_timeout(1000) -- 1 sec
	local ok, err = red:connect(config.redisHost, 6379)
	if not ok then
	    print("failed to connect: "..err)
	    return
	end

	-- 请注意这里 auth 的调用过程
	local count
	count, err = red:get_reused_times()
	if 0 == count then
	    ok, err = red:auth(config.redisSecret)
	    if not ok then
	        print("failed to auth: "..err)
	        return
	    end
	elseif err then
	    print("failed to get reused times: "..err)
	    return
	end
	return setmetatable({red = red}, mt)
end

function _M.close( self )
	local ok, err = self.red:set_keepalive(10000, 100)
    if not ok then
        print("failed to set keepalive: "..err)
        return
    end
end

function _M.getOptionStatusByName( self, name)
	status = self.red:hget(config.optionMap, name)
	if status == "on" then
		return true
	elseif status == "off" then
		return false
	end
	common.exitWithMsg("the option in redis is invalid", ngx.HTTP_INTERNAL_SERVER_ERROR )
end

function _M.getSetByName(self, name)
	return self.red:smembers(name)
end

function _M.publishLog( self, log )
	local logJson = json.encode(log)
	return self.red:publish(config.redisChannel, logJson)
end


function _M.getCCDenyRate( self )
	local count = self.red:hget("ccrate", "count")
	local seconds = self.red:hget("ccrate", "seconds")
	return count, seconds
end

return _M