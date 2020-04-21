local common = require "xwaf.common"
local _M = {
	checkName = "args"
}
local mt = {__index = _M}

function _M.new(self, redis)
	return setmetatable({redis=redis}, mt)
end

function _M.check( self, client )
	
	if common.switch(self.redis, self.checkName) then
		ruleSet = self.redis:getSetByName(self.checkName)
		uriArgs = common:getUriArgs()
		if uriArgs then
			client.uriArgs = uriArgs
			pass, rule, target = common:checkPostOrGetArgsV1(uriArgs, ruleSet)
			if pass == false then
				client.pass = false
				table.insert(client.attackInfo, {type="args",
				 message="the args of this request is invalid", rule=rule, target=target})
				return common.publishToRedisAndExit(self.redis, client, 
					"your request is dangerous", ngx.HTTP_FORBIDDEN)
			end
		end
		

	end
end
return _M