local _M = {
	remoteAddr = "",
	requestTime = "",
	requestMethod = "",
	requestUri = "",
	contentLength = "",
	userAgent = "",
	serverProtocol = "",
	serverPort = "",
	remotePort = "",
	httpReferer = "",
	httpCookie = "",
	contentType = "",
	uriArgs = "",
	bodyArgs = "",
	scheme = "",
	uploadFileName = "",
	attackInfo = {},
	pass = "",
	httpRawHeader = ""
}

local mt = {__index = _M}
function _M.new(self)
	return setmetatable({}, mt)
end

function _M.initLog(self)
	self.remoteAddr = ngx.var.remote_addr or ""
	self.requestTime = ngx.time()
	self.requestMethod = ngx.var.request_method
	self.requestUri = ngx.var.request_uri
	self.contentLength = ngx.var.content_length or 0
	self.userAgent = ngx.var.http_user_agent or ""
	self.serverProtocol = ngx.var.server_protocol
	self.serverPort = ngx.var.server_port
	self.remotePort = ngx.var.remote_port
	self.httpReferer = ngx.var.http_referer or ""
	self.httpCookie = ngx.var.http_cookie or ""
	self.contentType = ngx.var.content_type or ""
	self.scheme = ngx.var.scheme
	self.uriArgs = {}
	self.bodyArgs = {}
	self.uploadFileName = ""
	self.attackInfo = {"attack"}
	self.pass = true
	self.httpRawHeader = ngx.req.raw_header() or ""
end


return _M