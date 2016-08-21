--[[
Multi-threaded hash
Copyright 2016 Xiang Zhang
--]]

local tds = require('tds')
local torch = require('torch')

local Atomic = require('tunnel.atomic')
local Serializer = require('tunnel.serializer')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Hash_ = torch.class('tunnel.Hash')

-- Constructor
function Hash_:__init()
   self.hash = Atomic(tds.Hash())
   self.serializer = Serializer()

   -- Lua 5.1 / LuaJIT garbage collection
   if newproxy then
      self.proxy = newproxy(true)
      getmetatable(self.proxy).__gc = function() self:__gc() end
   end

   return self
end

-- Get an item
function Hash_:get(key)
   local storage_string, status = self.hash:read(
      function (hash)
         return hash[key], true
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return self.serializer:retain(storage), status
   else
      return nil, status
   end

   return self
end

-- Get an item asynchronously
function Hash_:getAsync(key)
   local storage_string, status = self.hash:readAsync(
      function (hash)
         return hash[key], true
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return self.serializer:retain(storage), status
   else
      return nil, status
   end
end

-- Set an item
function Hash_:set(key, value)
   if value ~= nil then
      local storage = self.serializer:save(value)
      return self.hash:write(
         function (hash)
            local old_value
            if hash[key] ~= nil then
               old_value = self.serializer:load(
                  torch.CharStorage():string(hash[key]))
            end
            hash[key] = storage:string()
            return true, old_value
         end)
   else
      return self.hash:write(
         function (hash)
            local old_value
            if hash[key] ~= nil then
               old_value = self.serializer:load(
                  torch.CharStorage():string(hash[key]))
            end
            hash[key] = nil
            return true, old_value
         end)
   end
end

-- Set an item asynchronously
function Hash_:setAsync(key, value)
   if value ~= nil then
      local storage = self.serializer:save(value)
      return self.hash:writeAsync(
         function (hash)
            local old_value
            if hash[key] ~= nil then
               old_value = self.serializer:load(
                  torch.CharStorage():string(hash[key]))
            end
            hash[key] = storage:string()
            return true, old_value
         end)
   else
      return self.hash:writeAsync(
         function (hash)
            local old_value
            if hash[key] ~= nil then
               old_value = self.serializer:load(
                  torch.CharStorage():string(hash[key]))
            end
            hash[key] = nil
            return true, old_value
         end)
   end
end

-- Read an item
function Hash_:read(key, callback)
   return self.hash:read(
      function (hash)
         local value
         local storage_string = hash[key]
         if storage_string then
            local storage = torch.CharStorage():string(storage_string)
            value = self.serializer:retain(storage)
         end
         return callback(value)
      end)
end

-- Read an item asynchronously
function Hash_:readAsync(key, callback)
   return self.hash:readAsync(
      function (hash)
         local value
         local storage_string = hash[key]
         if storage_string then
            local storage = torch.CharStorage():string(storage_string)
            value = self.serializer:retain(storage)
         end
         return callback(value)
      end)
end

-- Write an item
function Hash_:write(key, callback)
   return self.hash:write(
      function (hash)
         local value
         local storage_string = hash[key]
         if storage_string then
            local storage = torch.CharStorage():string(storage_string)
            value = self.serializer:load(storage)
         end
         local new_value = callback(value)
         if new_value ~= nil then
            local new_storage = self.serializer:save(new_value)
            hash[key] = new_storage:string()
         else
            hash[key] = nil
         end
         return true, new_value
      end)
end

-- Write an item asynchronously
function Hash_:writeAsync(key, callback)
   return self.hash:writeAsync(
      function (hash)
         local value
         local storage_string = hash[key]
         if storage_string then
            local storage = torch.CharStorage():string(storage_string)
            value = self.serializer:load(storage)
         end
         local new_value = callback(value)
         if new_value ~= nil then
            local new_storage = self.serializer:save(new_value)
            hash[key] = new_storage:string()
         else
            hash[key] = nil
         end
         return true, new_value
      end)
end

-- Get the size of the hash table
function Hash_:size()
   return self.hash:read(
      function (hash)
         return #hash
      end)
end

-- Get the size of the hash table asynchronously
function Hash_:sizeAsync()
   return self.hash:readAsync(
      function (hash)
         return #hash
      end)
end

-- Iterate through all the items
function Hash_:iterator()
   local clone = self.hash:read(
      function (hash)
         local clone = tds.Hash()
         for key, value in pairs(hash) do
            clone[key] =
               self.serializer:save(
                  self.serializer:retain(
                     torch.CharStorage():string(value))):string()
         end
         return clone
      end)
   if clone then
      local iterator = pairs(clone)
      return function ()
         local key, value = iterator()
         if value ~= nil then
            local storage = torch.CharStorage():string(value)
            return key, self.serializer:load(storage)
         end
         return key, value
      end, true
   end
end

-- Iterate through all the items asynchronously
function Hash_:iteratorAsync()
   local clone = self.hash:readAsync(
      function (hash)
         local clone = tds.Hash()
         for key, value in pairs(hash) do
            clone[key] =
               self.serializer:save(
                  self.serializer:retain(
                     torch.CharStorage():string(value))):string()
         end
         return clone
      end)
   if clone then
      local iterator = pairs(clone)
      return function ()
         local key, value = iterator()
         if value ~= nil then
            local storage = torch.CharStorage():string(value)
            return key, self.serializer:load(storage)
         end
         return key, value
      end, true
   end
end

-- Convert to string
function Hash_:toString()
   return self.hash:read(
      function (hash)
         return tostring(hash)
      end)
end

-- Convert to string asynchronously
function Hash_:toStringAsync()
   return self.hash:readAsync(
      function (hash)
         return tostring(hash)
      end)
end

-- Free the resources allocated by hash
-- TODO (xiang): implement free by counting how many instances are using it
function Hash_:free()
end

-- The index operator
function Hash_:__index(key)
   local method = Hash_[key]
   if method then
      return method
   else
      return self:get(key)
   end
end

-- The new index operator
function Hash_:__newindex(key, value)
   -- Filter out function members
   local method = Hash_[key]
   if method then
      error('Cannot set when key is method name. Use Hash:set(key, value).')
   end
   -- Filter out data members
   if key == 'hash' or key == 'serializer' or key == 'proxy' then
      rawset(self, key, value)
   else
      self:set(key, value)
   end
end

-- To string
function Hash_:__tostring()
   return self:toString()
end

-- Table iterator operator
function Hash_:__pairs()
   return self:iterator()
end

function Hash_:__gc()
   self:free()
end

-- Serialization of this object
function Hash_:__write(f)
   f:writeObject(self.hash)
end

-- Deserialization of this object
function Hash_:__read(f)
   self.hash = f:readObject()
   self.serializer = Serializer()
end

-- Return the class, not the metatable
return tunnel.Hash
