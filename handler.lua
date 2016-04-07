-- Extending the Base Plugin handler is optional, as there is no real
-- concept of interface in Lua, but the Base Plugin handler's methods
-- can be called from your child implementation and will print logs
-- in your `error.log` file (where all logs are printed).
local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.header-transfer.access"

local RequestHeaderHandler = BasePlugin:extend()

-- Your plugin handler's constructor. If you are extending the
-- Base Plugin handler, it's only role is to instanciate itself
-- with a name. The name is your plugin name as it will be printed in the logs.
function RequestHeaderHandler:new()
  RequestHeaderHandler.super.new(self, "header-transfer")
end

function RequestHeaderHandler:access(conf)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  RequestHeaderHandler.super.access(self)

  -- Implement any custom logic here
  access.execute(conf)
end

-- Executed after oAuth2 & request-transformer plugins
-- @see https://getkong.org/docs/0.7.x/proxy/#5-plugins-execution
-- Kong executes the highest priority plugin
RequestHeaderHandler.PRIORITY = 600

-- This module needs to return the created table, so that Kong
-- can execute those functions.
return RequestHeaderHandler
