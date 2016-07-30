--[[
Multi-threaded hash
Copyright 2016 Xiang Zhang
--]]

local serialize = require('threads.sharedserialize')
local tds = require('tds')
local torch = require('torch')

local Atomic = require('tunnel.atomic')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Hash_ = torch.class('tunnel.Hash')

-- Constructor
function Hash_:__init()
   self.hash = Atomic(tds.Hash())
   return self
end

-- Set an item
function Hash_:set(key, value)
   local storage = serialize.save(value)
   return self.hash:write(
      function (hash)
         hash[key] = storage:string()
         return true
      end)
end

-- Set an item asynchronously
function Hash_:setAsync(key, value)
   local storage = serialize.save(value)
   return self.hash:writeAsync(
      function (hash)
         hash[key] = storage:string()
         return true
      end)
end

-- Get an item
function Hash_:get(key)
   local storage_string, status = self.hash:read(
      function (hash)
         return hash[key], true
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage), status
   else
      return nil, status
   end
end

-- Get an item asynchronously
function Hash_:getAsync(key)
   local storage_string, status = self.hash:read(
      function (hash)
         return hash[key], true
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage), status
   else
      return nil, status
   end
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
            clone[key] = value
         end
         return clone
      end)
   if clone then
      local iterator = pairs(clone)
      return function ()
         return iterator()
      end, true
   end
end

-- Iterate through all the items asynchronously
function Hash_:iterator()
   local clone = self.hash:readAsync(
      function (hash)
         local clone = tds.Hash()
         for key, value in pairs(hash) do
            clone[key] = value
         end
         return clone
      end)
   if clone then
      local iterator = pairs(clone)
      return function ()
         return iterator()
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
   if key == 'hash' then
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

-- Serialization of this object
function Hash_:__write(f)
   f:writeObject(self.hash)
end

-- Deserialization of this object
function Hash_:__read(f)
   self.hash = f:readObject()
end

-- Return the class, not the metatable
return tunnel.Hash
