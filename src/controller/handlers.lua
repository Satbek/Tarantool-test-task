#!/usr/bin/env tarantool

handlers = {}

local util = require('util')
local json = require('json')
local log = require('log')

local function invalid_key(req)
    log.info("invalid key = " .. req:stash('id') .. " from " .. tostring(req.peer.host))
    local resp = req:render {
        text = "No key Found \n\r"
    }
    resp.status = 404
    return resp
end

local function delete_key(req)
    local key = req:stash('id')
    if box.space.key_value:count(key) == 0 then
        log.info("invalid key from " .. tostring(req.peer.host))
        return invalid_key(req)
    end
    box.space.key_value:delete{key}
    log.info("delete key = " .. key .. " from " .. tostring(req.peer.host))
    local resp = req:render {
        text = 'record with key = ' .. key .. ' was deleted' .. "\n\r"
    }
    resp.status = 200
    return resp
end

local function get_key(req)
    local key = req:stash('id')
    if box.space.key_value:count(key) == 0 then
        return invalid_key(req)
    else
        log.info("get valid key = " .. key .. " from " .. tostring(req.peer.host))
        local resp = req:render {
            text = box.space.key_value:select{key}[1][2] .. "\n\r"
        }
        resp.status = 200
        return resp
    end
end

local function incorrect_body(req)
    local resp = req:render{
        text = 'invalid json: ' .. req:read_cached() .. "\n\r"
    }
    resp.status = 400
    log.info("got invalid json = " .. req:read_cached() .. " from " .. tostring(req.peer.host))
    return resp
end

local function key_already_exist(req, key)
    local resp = req:render{
        text = 'key = ' .. key .. ' already exists' .. "\n\r"
    }
    resp.status = 409
    log.info("request to existed key = " .. key .. " from " .. tostring(req.peer.host))
    return resp
end

local function add_key(req)
    --409 if exist
    --400 json incorrect

    local body = req:read_cached()
    if not util.is_valid_json(body) then
        return incorrect_body(req)
    elseif not util.is_valid_json_fields(json.decode(body), req.method) then
        return incorrect_body(req)
    end
    local key = tostring(json.decode(body)['key'])
    local value = tostring(json.encode(json.decode(body)['value']))
    if box.space.key_value:count(key) ~= 0 then
        return key_already_exist(req, key)
    end

    box.space.key_value:insert{key, value}
    local resp = req:render{
        text = 'added key = ' .. key .. ' value = ' .. value .. "\n\r"
    }
    resp.status = 200
    log.info("add key = " .. key  .. ", value = " .. value .. " from " .. tostring(req.peer.host))
    return resp
end

local function update_key(req)
    local key = req:stash('id')
    if box.space.key_value:count(key) == 0 then
        return invalid_key(req)
    end
    local body = req:read_cached()
    if not util.is_valid_json(body) then
        return incorrect_body(req)
    elseif not util.is_valid_json_fields(json.decode(body), req.method) then
        return incorrect_body(req)
    end
    local value = tostring(json.encode(json.decode(body)['value']))
    box.space.key_value:update(key, {{'=', 2, value}})
    local resp = req:render {
        text = 'key = ' .. key .. ' updated;' .. ' new value is ' .. value .. "\n\r"
    }
    log.info('key = ' .. key .. ' updated;' .. ' new value is ' .. value .. ' from ' .. tostring(req.peer.host))
    resp.status = 200
    return resp
end

handlers = {
    delete_key = delete_key,
    get_key = get_key,
    add_key = add_key,
    update_key = update_key
}

return handlers
