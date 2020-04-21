local common = require "xwaf.common"

local _M = {
	checkName = "whiteip"
}

local mt = {__index = _M}


function _M.new(self, redis)
	return setmetatable({redis=redis}, mt)
end

function _M.check( self, client)
	if common.switch(self.redis, self.checkName) then
		ruleSet = self.redis:getSetByName(self.checkName)
		for _, item in pairs(ruleSet) do
			if client.remoteAddr == item then
				return
			end
		end 
		client.pass = false
		table.insert(client.attackInfo, {type="whiteip", message="the ip is not in the set of whiteip", rule="", target="" })
		return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
	end
end

return _M