#!/usr/bin/env tarantool

require('strict').on()

storage_manager = {}

--Storage_manager class implements operations with key-value storage

function storage_manager:new(space_name)
    -- space_name - name of existed space
    -- space must have al least two fields
    -- first - key, second - value
    local obj = {}
        obj.space_name = space_name

    function obj:get(key)
        local err, value = nil, nil
        if box.space[obj.space_name]:count(key) == 0 then
            err = 'No such key'
        else
            value = box.space[obj.space_name]:get{key}[2]
        end
        return err, value
    end

    function obj:add(key, value)
        local err = nil
        if box.space[obj.space_name]:count(key) ~= 0 then
            err = 'Key already exist'
        else
            box.space[obj.space_name]:insert{key, value}
        end
        return err
    end
    
    function obj:update(key, value)
        local err = nil
        if box.space[obj.space_name]:count(key) == 0 then
            err = 'No such key'
        else
            box.space[obj.space_name]:update(key, {{'=', 2, value}})
        end
        return err
    end

    function obj:delete(key)
        local err = nil
        if box.space[obj.space_name]:count(key) == 0 then
            err = 'No such key'
        else
            box.space[obj.space_name]:delete{key}
        end
        return err
    end

    setmetatable(obj, self)
    self.__index = self; 
    return obj
end

return storage_manager