


local logInfo = require "xwaf.logInfo"
local myRedis = require "xwaf.myRedis"
local common = require "xwaf.common"
local whiteIpCheck = require "xwaf.whiteIpCheck"
local whiteUrlCheck = require "xwaf.whiteUrlCheck"
local blackIpCheck = require "xwaf.blackIpCheck"
local blackUrlCheck = require "xwaf.blackUrlCheck"
local ccCheck = require "xwaf.ccCheck"
local argsCheck = require "xwaf.argsCheck"
local urlCheck = require "xwaf.urlCheck"
local bodyCheck = require "xwaf.bodyCheck"
local uaCheck = require "xwaf.uaCheck"
local cookieCheck = require "xwaf.cookieCheck"
local timeHelper = require "xwaf.timeHelper"
local cjson = require "cjson"
local startTime = timeHelper.current_time_millis()
print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< waf start at: "..startTime)

local client = logInfo:new()
local redis = myRedis:new()
local whiteIpChecker = whiteIpCheck:new(redis)
local whiteUrlChecker = whiteUrlCheck:new(redis)
local blackIpChecker = blackIpCheck:new(redis)
local blackUrlChecker = blackUrlCheck:new(redis)
local ccChecker = ccCheck:new(redis)
local argsChecker = argsCheck:new(redis)
local urlChecker = urlCheck:new(redis)
local bodyChecker = bodyCheck:new(redis)
local uaChecker = uaCheck:new(redis)
local cookieChecker = cookieCheck:new(redis)

client:initLog()

whiteIpChecker:check(client)
blackIpChecker:check(client)
whiteUrlChecker:check(client)
blackUrlChecker:check(client)
ccChecker:check(client)
uaChecker:check(client)
cookieChecker:check(client)
urlChecker:check(client)
argsChecker:check(client)
bodyChecker:check(client)


redis:publishLog(client)
redis:close()

local endTime = timeHelper.current_time_millis()
print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> waf finish at: "..endTime)
print("time cost: "..endTime-startTime)



