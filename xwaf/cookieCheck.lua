local common = require "xwaf.common"

local _M = {
	checkName = "cookie"
}

local mt = {__index = _M}


function _M.new(self, redis)
	return setmetatable({redis=redis}, mt)
end

function _M.check( self, client)
	if common.switch(self.redis, self.checkName) then
		ruleSet = self.redis:getSetByName(self.checkName)
		for _, rule in pairs(ruleSet) do
			m = ngx.re.match(client.httpCookie, rule, "isjo")
			if m then
				client.pass = false
				table.insert(client.attackInfo, {type="cookie",
				 message="the cookie of this request is invalid", rule=rule, target=m[0]})
				return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
			end
		end 
		
	end
end

return _M