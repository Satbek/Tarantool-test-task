#!/usr/bin/env tarantool

require('strict').on()

handlers = {}

local util = require('util')
local json = require('json')
local log = require('log')

local key_value = require('storage_manager'):new('key_value')

local function get_request_info(req)
    return string.format("host = %s, port = %s, method = %s, args = %s, body = %s",
        req.peer.host, req.peer.port, req.method,
        req.query, req:read_cached())
end

local function invalid_key(req)
    log.info("get invalid key = '%s' from %s", req:stash('id'), get_request_info(req))
    local resp = req:render {
        text = "No key Found \n\r"
    }
    resp.status = 404
    return resp
end

local function incorrect_body(req)
    local resp = req:render{
        text = string.format('invalid json: %s\n', req:read_cached())
    }
    resp.status = 400
    log.info("got invalid json = %s from %s", req:read_cached(), get_request_info(req))
    return resp
end

local function key_already_exist(req, key)
    local resp = req:render{
        text = string.format('key = %s already exists\n', key)
    }
    resp.status = 409
    log.info("request to existed key = '%s' from %s", key, get_request_info(req))
    return resp
end

local function delete(req)
    local key = req:stash('id')
    local err = key_value:delete(key)
    if err ~= nil then
        return invalid_key(req)
    end
    log.info("delete key = '%s' from %s", key, get_request_info(req))
    local resp = req:render {
        text = string.format("record with key = %s was deleted\n", key)
    }
    resp.status = 200
    return resp
end

local function get(req)
    local key = req:stash('id')
    local err, value = key_value:get(key)
    if err ~= nil then
        return invalid_key(req)
    else
        log.info("get valid key = '%s', value = %s from %s", key, value, get_request_info(req))
        local resp = req:render {
            text = string.format("key = %s, value = %s\n", key, value)
        }
        resp.status = 200
        return resp
    end
end

local function add(req)
    local body = req:read_cached()
    local ok, body = pcall(function() return req:json() end)
    if not ok then
        return incorrect_body(req)
    elseif not util.is_valid_json_fields(body, req.method) then
        return incorrect_body(req)
    end

    local key = tostring(body['key'])
    local value = tostring(json.encode(body['value']))

    local err = key_value:add(key, value)
    if err ~= nil then
        return key_already_exist(req, key)
    end

    local resp = req:render{
        text = string.format("added key = %s, value = %s\n", key, value)
    }
    resp.status = 200
    log.info("add key = '%s', value = %s from", key, value, get_request_info(req))
    return resp
end

local function update(req)
    local key = req:stash('id')
    local ok, body = pcall(function() return req:json() end)
    if not ok then
        return incorrect_body(req)
    elseif not util.is_valid_json_fields(body, req.method) then
        return incorrect_body(req)
    end

    local value = tostring(json.encode(body['value']))
    local err = key_value:update(key, value)

    if err ~= nil then
        return invalid_key(req)
    end

    local resp = req:render {
        text = string.format("key = %s updated; new value is %s\n", key, value)
    }

    log.info("update key = '%s', new_value = %s from %s", key, value, get_request_info(req))
    resp.status = 200
    return resp
end

handlers = {
    delete = delete,
    get = get,
    add = add,
    update = update
}

return handlers
