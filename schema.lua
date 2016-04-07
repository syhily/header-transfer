return {
  -- this plugin will only be API-wide
  -- Only for plugin which have enabled oAuth2 authentication
  no_consumer = true,
  fields = {
    -- Describe your plugin's configuration's schema here.
    head_to_body = {
      type = "array",
      default = {}
    }
  },
  -- @param `schema` A table describing the schema (rules) of your plugin configuration.
  -- @param `config` A key/value table of the current plugin's configuration.
  -- @param `dao` An instance of the DAO (see DAO chapter).
  -- @param `is_updating` A boolean indicating wether or not this check is performed in the context of an update.
  -- @return `valid` A boolean indicating if the plugin's configuration is valid or not.
  -- @return `error` A DAO error (see DAO chapter)
  self_check = function(schema, plugin_t, dao, is_updating)
    -- TODO perform any custom verification
    return true
  end
}
