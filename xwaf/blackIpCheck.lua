local common = require "xwaf.common"

local _M = {
	checkName = "blackip"
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
				client.pass = false
				table.insert(client.attackInfo, {type="blackip",
					message="the ip is in the set of blackip", rule=item, target=item })
				return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
			end
		end 
	end
end

return _M