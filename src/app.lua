#!/usr/bin/env tarantool
require'strict'.on()

box.cfg{
    listen = 3301,
    --log = 'app.log'
}

local app_folder = os.getenv('PWD')

package.path = app_folder .. "/controller/?.lua;" .. package.path

local handlers = require('handlers')

local log = require('log')


local setUpBase = function()
    box.once('init', function()
        box.schema.create_space('key_value')
        box.space.key_value:format({
            {name = 'key', type = 'string'},
            {name = 'value', type = 'string'}
        })
        box.space.key_value:create_index('primary', {parts = {'key'}, type = 'HASH'})
        end
    )
    log.info('Started')
    return true
end

setUpBase()

local server = require('http.server').new(nil, 8080)
server:route({ path = '/kv/:id', method = 'GET'}, handlers.get_key)
server:route({ path = '/kv', method = 'POST'}, handlers.add_key)
server:route({ path = '/kv/:id', method = 'DELETE'}, handlers.delete_key)
server:route({ path = '/kv/:id', method = 'PUT'}, handlers.update_key)
server:start()
