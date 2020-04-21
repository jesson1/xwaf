
local common = require "xwaf.common"
local _M = {
	checkName = "whiteurl"
}

local mt = {__index = _M}


function _M.new(self, redis)
	return setmetatable({redis=redis}, mt)
end

function _M.check( self, client)
	if common.switch(self.redis, self.checkName) then
		ruleSet = self.redis:getSetByName(self.checkName)
		for _, rule in pairs(ruleSet) do
			if ngx.re.match(client.requestUri, rule, "isjo") then
				return
			end
		end 
		client.pass = false
		table.insert(client.attackInfo, {type="whiteurl", message="the request url is not in the set of whiteurl", rule="", target="" })
		return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
	end
end

return _M