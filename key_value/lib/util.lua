#!/usr/bin/env tarantool

require'strict'.on()

util = {}

local log = require('log')

local function get_map_size(map)
    local size = 0
    for _ in pairs(map) do size = size + 1; end
    return size
end

local function is_valid_json_fields(body, method)
    local result = true
    if string.lower(method) == string.lower('POST') then
        if get_map_size(body) ~= 2 or body['key'] == nil or body['value'] == nil then
            result = false
        end
    elseif string.lower(method) == string.lower('PUT') then
        if get_map_size(body) ~= 1 or body['value'] == nil then
            result = false
        end
    else
        log.error("unsupported reuest method = %s", method)
        result = false
    end
    return result
end

util = {
    is_valid_json_fields = is_valid_json_fields
}

return util