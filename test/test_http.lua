#!/usr/bin/env tarantool

require'strict'.on()

local http_client = require('http.client')
local tap = require('tap')

local port = os.getenv('PORT')
if port == nil then
    port = 8080
end

local URI = string.format("localhost:%d", port)

test_get = tap.test("test GET, get key")
test_get:plan(2)
test_get:test("get value, by key", function(test)
    test:plan(1)
    http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    local resp_positive = http_client.get(URI .. "/kv/test")
    http_client.delete(URI .. "/kv/test")
    test:is(resp_positive.status, 200)
end)

test_get:test("get invalid key", function(test)
    test:plan(1)
    http_client.delete(URI .. "/kv/test")
    local resp_negative = http_client.get(URI .. "/kv/test")
    test:is(resp_negative.status, 404)
end)

test_get:check()

test_post = tap.test("test POST, add key")
test_post:plan(3)
test_post:test("add value by key", function(test)
    test:plan(1)
    local resp_positive = http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    http_client.delete(URI .. "/kv/test")
    test:is(resp_positive.status, 200)
end)

test_post:test("incorrect body", function(test)
    test:plan(4)
    local resp_bad_json = http_client.post(URI .. "/kv", '{"key":"1"')
    test:is(resp_bad_json.status, 400)
    local resp_excess_field = 
         http_client.post(URI .. "/kv",'{"key":"test", "value":"1", "extra":1}')
    test:is(resp_excess_field.status, 400)
    local resp_no_key = 
        http_client.post(URI .. "/kv",'{"value":"1"}')
    test:is(resp_no_key.status, 400)
    local resp_no_value =
        http_client.post(URI .. "/kv",'{"key":"test"}')
    test:is(resp_no_key.status, 400)
end)

test_post:test("existed key", function(test)
    test:plan(1)
    http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    local resp = http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    test:is(resp.status, 409)
    http_client.delete(URI .. "/kv/test")
end)

test_post:check()

test_delete = tap.test("test DELETE, delete key")
test_delete:plan(2)
test_delete:test("delete record", function(test)
    test:plan(1)
    http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    local resp = http_client.delete(URI .. "/kv/test")
    test:is(resp.status, 200)
end)

test_delete:test("get invalid key", function(test)
    test:plan(1)
    http_client.delete(URI .. "/kv/test")
    local resp = http_client.delete(URI .. "/kv/test")
    test:is(resp.status, 404)
end)

test_delete:check()

test_put = tap.test("test PUT, update value")
test_put:plan(3)
test_put:test("update value by key", function(test)
    test:plan(1)
    http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    local resp = http_client.put(URI .. "/kv/test", '{"value":"2"}')
    http_client.delete(URI .. "/kv/test")
    test:is(resp.status, 200)
end)

test_put:test("invalid key", function(test)
    test:plan(1)
    http_client.delete(URI .. "/kv/test")
    local resp = http_client.put(URI .. "/kv/test", '{"value":2}')
    test:is(resp.status, 404)
end)

test_put:test("incorrect body", function(test)
    test:plan(3)
    http_client.post(URI .. "/kv", '{"key":"test", "value":"1"}')
    local resp_bad_json = http_client.put(URI .. "/kv/test", '{"value":"1"')
    test:is(resp_bad_json.status, 400)
    local resp_excess_field = 
         http_client.put(URI .. "/kv/test",'{"value":"1", "extra":1}')
    test:is(resp_excess_field.status, 400)
    local resp_no_value =
        http_client.put(URI .. "/kv/test",'{"key":"test"}')
    test:is(resp_no_value.status, 400)
    http_client.delete(URI .. "/kv/test")
end)

test_put:check()

test_request_method_case = tap.test("Different cases of method in request")

test_request_method_case:plan(1)
test_request_method_case:test("different cases", function(test)
    test:plan(2)
    http_client.request("POST", URI .. "/kv", '{"key":"test", "value":"1"}')
    local resp_bad_json = http_client.request("put", URI .. "/kv/test", '{"value":"1", "extra":"2"}')
    test:is(resp_bad_json.status, 400)
    http_client.delete(URI .. "/kv/test")
    local resp_no_key = 
        http_client.request("post", URI .. "/kv",'{"value":"1", "key":"test", "extra":"test"}')
    test:is(resp_no_key.status, 400)
    http_client.delete(URI .. "/kv/test")
end)

test_request_method_case:check()
os.exit(0)
