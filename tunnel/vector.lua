--[[
Multi-threaded vector
Copyright 2016 Xiang Zhang
--]]

local ffi = require('ffi')
local serialize = require('threads.sharedserialize')
local tds = require('tds')
local threads = require('threads')
local torch = require('torch')

local Atomic = require('tunnel.atomic')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Vector_ = torch.class('tunnel.Vector')

-- Constructor
-- The parameters can be a list of items, in a table or not.
function Vector_:__init(...)
   self.vector = Atomic(tds.Vec())
   if select('#', ...) == 1 and type(select(1, ...)) == 'table' then
      for index, value in ipairs(select(1, ...)) do
         self:append(value)
      end
   elseif select('#', ...) > 0 then
      for index, value in ipairs({...}) do
         self:append(value)
      end
   end
   return self
end

-- Insert an item
function Vector_:insert(...)
   if select('#', ...) == 1 then
      local storage = serialize.save(select(1, ...))
      return self.vector:write(
         function (vector)
            vector:insert(storage:string())
            return true
         end)
   else
      local key, value = select(1, ...), select(2, ...)
      local storage = serialize.save(value)
      return self.vector:write(
         function (vector)
            vector:insert(key, storage:string())
            return true
         end)
   end
end

-- Insert an item asynchronously
function Vector_:insertAsync(...)
   if select('#', ...) == 1 then
      local storage = serialize.save(select(1, ...))
      return self.vector:writeAsync(
         function (vector)
            vector:insert(storage:string())
            return true
         end)
   else
      local key, value = select(1, ...), select(2, ...)
      local storage = serialize.save(value)
      return self.vector:writeAsync(
         function (vector)
            vector:insert(key, storage:string())
            return true
         end)
   end
end

-- Remove an item
function Vector_:remove(index)
   local storage_string = self.vector:write(
      function (vector)
         local index = index or #vector
         local storage_string = vector[index]
         vector:remove(index)
         return storage_string
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage)
   end
end

-- Remove an item asynchronously
function Vector_:removeAsync(index)
   local storage_string = self.vector:writeAsync(
      function (vector)
         local index = index or #vector
         local storage_string = vector[index]
         vector:remove(index)
         return storage_string
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage)
   end
end

-- Push the item at the front
function Vector_:pushFront(value)
   return self:insert(1, value)
end

-- Push the item at the front asynchronously
function Vector_:pushFrontAsync(value)
   return self:insertAsync(1, value)
end

-- Pop the item at the front
function Vector_:popFront()
   return self:remove(1)
end

-- Pop the item at the front asynchronously
function Vector_:popFrontAsync()
   return self:removeAsync(1)
end

-- Push the item at the back
function Vector_:pushBack(value)
   return self:insert(value)
end

-- Push the item at the back asynchronously
function Vector_:pushBackAsync(value)
   return self:insertAsync(value)
end

-- Pop the item at the back
function Vector_:popBack()
   return self:remove()
end

-- Pop the item at the back asynchronously
function Vector_:popBackAsync()
   return self:removeAsync()
end

-- Get the item
function Vector_:get(index)
   local storage_string = self.vector:read(
      function (vector)
         return vector[index]
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage)
   end
end

-- Get the item asynchronously
function Vector_:getAsync(index)
   local storage_string = self.vector:readAsync(
      function (vector)
         return vector[index]
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage)
   end
end

-- Set the item
function Vector_:set(index, value)
   local storage = serialize.save(value)
   return self.vector:write(
      function (vector)
         vector[index] = storage:string()
         return true
      end)
end

-- Set the item asynchronously
function Vector_:setAsync(index, value)
   local storage = serialize.save(value)
   return self.vector:write(
      function (vector)
         vector[index] = storage:string()
         return true
      end)
end

-- Get the size of the vector
function Vector_:size()
   return self.vector:read(
      function (vector)
         return #vector
      end)
end

-- Get the size of the vector asynchronously
function Vector_:sizeAsync()
   return self.vector:readAsync(
      function (vector)
         return #vector
      end)
end

-- Sort the vector
function Vector_:sort(compare)
   return self.vector:write(
      function (vector)
         vector:sort(compare)
         return true
      end)
end

-- Sort the vector asynchronously
function Vector_:sortAsync(compare)
   return self.vector:writeAsync(
      function (vector)
         vector:sort(compare)
         return true
      end)
end

-- Iterate through all the items
function Vector_:iterator()
   local clone = self.vector:read(
      function (vector)
         local clone = tds.Vec()
         for index, value in ipairs(vector) do
            clone[index] = value
         end
         return clone
      end)
   if clone then
      local index = 0
      return function ()
         index = index + 1
         if index <= #clone then
            return index, serialize.load(
               torch.CharStorage():string(clone[index]))
         end
      end
   end
end

-- Iterate through all the items asynchronously
function Vector_:iteratorAsync()
   local clone = self.vector:readAsync(
      function (vector)
         local clone = tds.Vec()
         for index, value in ipairs(vector) do
            clone[index] = value
         end
         return clone
      end)
   if clone then
      local index = 0
      return function ()
         index = index + 1
         if index <= #clone then
            return index, serialize.load(
               torch.CharStorage():string(clone[index]))
         end
      end
   end
end

-- Convert to string
function Vector_:tostring()
   return self.vector:read(
      function (vector)
         return tostring(vector)
      end)
end

-- Convert to string asynchronously
function Vector_:tostringAsync()
   return self.vector:read(
      function (vector)
         return tostring(vector)
      end)
end

-- Return the class, not the metatable
return tunnel.Vector
