#!/usr/bin/env tarantool

util = {}
local json = require('json')

local function is_valid_json(body)
    local result = true
    if not pcall(function() json.decode(body) end) then
        result = false
    end
    return result
end

local function get_map_size(map)
    local size = 0
    for _ in pairs(map) do size = size + 1; end
    return size
end

local function is_valid_json_fields(body, method)
    local result = true
    if method == 'POST' then
        if get_map_size(body) ~= 2 or body['key'] == nil or body['value'] == nil then
            result = false
        end
    elseif method == 'PUT' then
        if get_map_size(body) ~= 1 or body['value'] == nil then
            result = false
        end
    end
    return result
end

util = {
    is_valid_json = is_valid_json,
    is_valid_json_fields = is_valid_json_fields
}

return util