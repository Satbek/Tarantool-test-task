#!/bin/sh
export LUA_PATH="$LUA_PATH;;$PWD/key_value/lib/?.lua"
tarantool ./key_value/app.lua