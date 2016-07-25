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

-- Append the item
function Vector_:append(value)
   local storage = serialize.save(value)
   return self.vector:write(
      function (vector)
         vector:insert(storage:string())
         return true
      end)
end

-- Append the item asynchronously
function Vector_:append_async(value)
   local storage = serialize.save(value)
   return self.vector:write_async(
      function (vector)
         vector:insert(storage:string())
         return true
      end)
end

-- Remove the last item
function Vector_:remove()
   local storage_string = self.vector:write(
      function (vector)
         local storage_string = vector[#vector]
         vector:remove()
         return storage_string
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage)
   end
end

-- Remove the last item asynchronously
function Vector_:remove_async()
   local storage_string = self.vector:write_async(
      function (vector)
         local storage_string = vector[#vector]
         vector:remove()
         return storage_string
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage)
   end
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
function Vector_:get_async(index)
   local storage_string = self.vector:read_async(
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
function Vector_:set_async(index, value)
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
function Vector_:size_async()
   return self.vector:read_async(
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
function Vector_:sort_async(compare)
   return self.vector:write_async(
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
function Vector_:iterator_async()
   local clone = self.vector:read_async(
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
function Vector_:tostring_async()
   return self.vector:read(
      function (vector)
         return tostring(vector)
      end)
end

-- Return the class, not the metatable
return tunnel.Vector
