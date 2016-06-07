-- Third Party Libs
local stringy = require "stringy"
local multipart = require "multipart"
local cjson = require "cjson"

-- Openresty Based Libs
local string_find = string.find
local string_len = string.len
local table_maxn = table.maxn
local req_clear_header = ngx.req.clear_header
local req_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local req_set_uri_args = ngx.req.set_uri_args
local req_get_uri_args = ngx.req.get_uri_args
local req_get_body_data = ngx.req.get_body_data
local req_set_body_data = ngx.req.set_body_data
local req_read_body = ngx.req.read_body
local encode_args = ngx.encode_args
local ngx_decode_args = ngx.decode_args

-- Lua Based Libs
local unpack = unpack
local pcall = pcall

local _M = {}

local CONTENT_LENGTH = "content-length"
local CONTENT_TYPE = "content-type"
-- Different HTTP POST TYPE
local JSON, MULTI, ENCODED = "json", "multi_part", "form_encoded"
local HTTP_METHOD = {
  POST = "POST",
  GET = "GET"
}

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end

local function decode_args(body)
  if body then
    return ngx_decode_args(body)
  end
  return {}
end

local function iter(config_array)
  return function(config_array, i, previous_name, previous_value)
    i = i + 1
    local current_pair = config_array[i]
    if current_pair == nil then -- n + 1
      return nil
    end
    local current_name, current_value = unpack(stringy.split(current_pair, ":"))
    return i, current_name, current_value
  end, config_array, 0
end

local function get_content_type(content_type)
  if content_type == nil then
    return
  end
  if string_find(content_type:lower(), "application/json", nil, true) then
    return JSON
  elseif string_find(content_type:lower(), "multipart/form-data", nil, true) then
    return MULTI
  elseif string_find(content_type:lower(), "application/x-www-form-urlencoded", nil, true) then
    return ENCODED
  end
end

local function transform_headers_to_url_encoded_body(new_body, body, content_length)
  local parameters = decode_args(body)
  if parameters == nil and content_length > 0 then return false, nil end -- Couldn't modify body
  if content_length >= 0 then
    for body_name, body_value in pairs(new_body) do
      parameters[body_name] = body_value
    end
  end
  return true, encode_args(parameters)
end

local function transform_headers_to_multipart_body(new_body, body, content_length, content_type_value)
  local parameters = multipart(body and body or "", content_type_value)
  if parameters == nil and content_length > 0 then return false, nil end -- Couldn't modify body
  if content_length > 0 then
    for body_name, body_value in pairs(new_body) do
      parameters[body_name] = body_value
    end
  end
  return true, parameters:tostring()
end

local function transform_headers_to_json_body(new_body, body, content_length)
  local content_length = (body and string_len(body)) or 0
  local parameters = parse_json(body)
  if parameters == nil and content_length > 0 then return false, nil end -- Couldn't modify body
  if content_length > 0 then
    for body_name, body_value in pairs(new_body) do
      parameters[body_name] = body_value
    end
  end
  return true, cjson.encode(parameters)
end

local function transform_headers_to_body(conf)
  local content_type_value = req_get_headers(0)[CONTENT_TYPE]
  local content_type = get_content_type(content_type_value)
  if content_type == nil or #conf.head_to_body < 1 then
    return -- POST body only supports three basic types.
  end

  local new_body = {}
  local have_to_trans = false
  for _, header_name, body_name in iter(conf.head_to_body) do
    local header_value = req_get_headers(0)[header_name] -- Harmful
    if header_value then -- Header shouldn't be nil
      req_clear_header(header_name)
      new_body[body_name] = header_value
      have_to_trans = true
    end
  end

  -- Call req_read_body to read the request body first
  if have_to_trans then
    req_read_body()
    local body = req_get_body_data()
    local is_body_transformed = false
    local content_length = (body and string_len(body)) or 0

    if content_type == MULTI then
      is_body_transformed, body = transform_headers_to_multipart_body(new_body, body, content_length, content_type_value)
    elseif content_type == JSON then
      is_body_transformed, body = transform_headers_to_json_body(new_body, body, content_length)
    else
      is_body_transformed, body = transform_headers_to_url_encoded_body(new_body, body, content_length)
    end

    if is_body_transformed then
      req_set_body_data(body)
      req_set_header(CONTENT_LENGTH, string_len(body))
    end
  end
end

local function transform_headers_to_querystring(conf)
  if #conf.head_to_body < 1 then
    return
  end

  local querystring = req_get_uri_args(0) -- Harmful
  if not querystring then
    querystring = {}
  end

  for _, header_name, param_name in iter(conf.head_to_body) do
    local header_value = req_get_headers(0)[header_name] -- Harmful
    if header_value then -- Header shouldn't be nil
      req_clear_header(header_name)
      querystring[param_name] = header_value
    end
  end
  req_set_uri_args(querystring)
end

-- This method would transfer head attribute to body or querystring based on request type
-- Only supports POST & GET method
function _M.execute(conf)
  local request_method = ngx.req.get_method()
  if HTTP_METHOD.GET == request_method then
    transform_headers_to_querystring(conf)
  elseif HTTP_METHOD.POST == request_method then
    transform_headers_to_body(conf)
  end
end

return _M
