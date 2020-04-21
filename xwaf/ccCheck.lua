local common = require "xwaf.common"

local _M = {
	checkName = "ccdeny"
}

local mt = {__index = _M}


function _M.new(self, redis)
	return setmetatable({redis=redis}, mt)
end

function _M.check( self, client)
	if common.switch(self.redis, self.checkName) then
		local count, seconds = self.redis:getCCDenyRate()
		count = tonumber(count)
		seconds = tonumber(seconds)
		local uri = client.requestUri
		local ip = client.remoteAddr
		local token = ip..uri
		local limit = ngx.shared.limit
		local req, _ = limit:get(token)
        if req then
            if req >= count then
            	client.pass = false
            	table.insert(client.attackInfo, {type="ccdeny", 
            		message="the request of "..token.." is out of ccdeny rate", rule="", target=""})
                return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
            else
                 limit:incr(token, 1)
            end
        else
            limit:set(token, 1, seconds)
        end
	end
end

return _M