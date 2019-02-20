#!/usr/bin/env tarantool
box.cfg{
    listen = 3301,
    pid_file = '1.pid'
    --log = 'app.log'
}

require'strict'.on()

local handlers = require('handlers')

local log = require('log')

local set_up_base = function ()
    box.once('init', function()
        box.schema.create_space('key_value')
        box.space.key_value:format({
            {name = 'key', type = 'string'},
            {name = 'value', type = 'string'}
        })
        box.space.key_value:create_index('primary', {parts = {'key'}})
        box.schema.user.grant('guest', 'read,write,execute', 'universe',
            nil, {if_not_exists = true})
        end
    )
    log.info('Base configured')
end

local function start_server()
    local port = os.getenv('PORT')
    if port == nil then
        port = 8080
    end
    local server = require('http.server').new(nil, port)
    server:route({ path = '/kv/:id', method = 'GET' }, handlers.get)
    server:route({ path = '/kv', method = 'POST' }, handlers.add)
    server:route({ path = '/kv/:id', method = 'DELETE' }, handlers.delete)
    server:route({ path = '/kv/:id', method = 'PUT' }, handlers.update)
    server:route({ path = '/', method = 'GET', file = 'main.html.lua' })
    server:start()
    log.info('Server started on port = %d', port)
end

set_up_base()

start_server()
