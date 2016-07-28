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
-- The parameter is just a size hint. The actual size may go beyond it.
-- Size hint is only useful in push and pop functions, where whether to wait for
-- pushing or popping is depend on the current size of the vector.
function Vector_:__init(size_hint)
   self.vector = Atomic(tds.Vec())
   self.size_hint = size_hint or math.huge

   -- Mutex and conditions for push and pop functions based on size hint
   self.mutex = threads.Mutex()
   self.inserted_condition = threads.Condition()
   self.removed_condition = threads.Condition()
   return self
end

-- Insert an item
function Vector_:insert(...)
   local status, inserted
   if select('#', ...) == 1 then
      local storage = serialize.save(select(1, ...))
      inserted = self.vector:write(
         function (vector)
            vector:insert(storage:string())
            return true
         end)
   else
      local index, value = select(1, ...), select(2, ...)
      local storage = serialize.save(value)
      inserted = self.vector:write(
         function (vector)
            -- When index > #vector + 1, tds.Vec.insert will result in
            -- segmentation fault.
            if index <= #vector + 1 then
               vector:insert(index, storage:string())
               return true
            end
         end)
   end
   if inserted == true then
      self.inserted_condition:signal()
   end
   return inserted
end

-- Insert an item asynchronously
function Vector_:insertAsync(...)
   local inserted = nil
   if select('#', ...) == 1 then
      local storage = serialize.save(select(1, ...))
      inserted = self.vector:writeAsync(
         function (vector)
            vector:insert(storage:string())
            return true
         end)
   else
      local index, value = select(1, ...), select(2, ...)
      local storage = serialize.save(value)
      inserted = self.vector:writeAsync(
         function (vector)
            -- When index > #vector + 1, tds.Vec.insert will result in
            -- segmentation fault.
            if index <= #vector + 1 then
               vector:insert(index, storage:string())
               return true
            end
         end)
   end
   if inserted == true then
      self.inserted_condition:signal()
   end
   return inserted
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
      self.removed_condition:signal()
      return serialize.load(storage), true
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
      self.removed_condition:signal()
      return serialize.load(storage), true
   end
end

-- Push the item at the front
-- The function will wait untill the vector is smaller than self.size_hint.
-- Note that there is no guarantee that after insertion the vector size will
-- be smaller than or equal to self.size_hint.
function Vector_:pushFront(value)
   while self:size() >= self.size_hint do
      self.mutex:lock()
      self.removed_condition:wait(self.mutex)
      self.mutex:unlock()
   end
   return self:insert(1, value)
end

-- Push the item at the front asynchronously
-- If vector is larger than self.size_hint or there are other threads accessing
-- it, return immediately.
function Vector_:pushFrontAsync(value)
   local size = self:sizeAsync()
   if size and size < self.size_hint then
      return self:insertAsync(1, value)
   end
end

-- Pop the item at the front
-- The function will wait untill the vector has more than one item.
function Vector_:popFront()
   while self:size() < 1 do
      self.mutex:lock()
      self.inserted_condition:wait(self.mutex)
      self.mutex:unlock()
   end
   local value, removed = self:remove(1)

   while removed ~= true do
      while self:size() < 1 do
         self.mutex:lock()
         self.inserted_condition:wait(self.mutex)
         self.mutex:unlock()
      end
      value, removed = self:remove(1)
   end

   return value, removed
end

-- Pop the item at the front asynchronously
-- If vector is smaller than 1 or there are other threads accessing it, return
-- immediately
function Vector_:popFrontAsync()
   local size = self:sizeAsync()
   if size and size > 0 then
      return self:removeAsync(1)
   end
end

-- Push the item at the back
-- The function will wait untill the vector is smaller than self.size_hint.
-- Note that there is no guarantee that after insertion the vector size will
-- be smaller than or equal to self.size_hint.
function Vector_:pushBack(value)
   while self:size() >= self.size_hint do
      self.mutex:lock()
      self.removed_condition:wait(self.mutex)
      self.mutex:unlock()
   end
   return self:insert(value)
end

-- Push the item at the back asynchronously
-- If vector is larger than self.size_hint or there are other threads accessing
-- it, return immediately.
function Vector_:pushBackAsync(value)
   local size = self:sizeAsync()
   if size and size < self.size_hint then
      return self:insertAsync(value)
   end
end

-- Pop the item at the back
-- The function will wait untill the vector has more than one item.
function Vector_:popBack()
   while self:size() < 1 do
      self.mutex:lock()
      self.inserted_condition:wait(self.mutex)
      self.mutex:unlock()
   end
   local value, removed = self:remove()

   while removed ~= true do
      while self:size() < 1 do
         self.mutex:lock()
         self.inserted_condition:wait(self.mutex)
         self.mutex:unlock()
      end
      value, removed = self:remove()
   end

   return value, removed
end

-- Pop the item at the back asynchronously
-- If vector is smaller than 1 or there are other threads accessing it, return
-- immediately
function Vector_:popBackAsync()
   local size = self:sizeAsync()
   if size and size > 0 then
      return self:removeAsync()
   end
end

-- Get the item
function Vector_:get(index)
   local storage_string, status = self.vector:read(
      function (vector)
         return vector[index], true
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage), status
   else
      return nil, status
   end
end

-- Get the item asynchronously
function Vector_:getAsync(index)
   local storage_string, status = self.vector:readAsync(
      function (vector)
         return vector[index], true
      end)
   if storage_string then
      local storage = torch.CharStorage():string(storage_string)
      return serialize.load(storage), status
   else
      return nil, status
   end
end

-- Set the item
function Vector_:set(index, value)
   local storage = serialize.save(value)
   return self.vector:write(
      function (vector)
         if index > #vector then
            local nil_string = serialize.save(nil):string()
            for i = #vector + 1, index do
               vector[i] = nil_string
            end
         end
         vector[index] = storage:string()
         return true
      end)
end

-- Set the item asynchronously
function Vector_:setAsync(index, value)
   local storage = serialize.save(value)
   return self.vector:write(
      function (vector)
         if index > #vector then
            local nil_string = serialize.save(nil):string()
            for i = #vector + 1, index do
               vector[i] = nil_string
            end
         end
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
         vector:sort(
            function (a, b)
               return compare(serialize.load(torch.CharStorage():string(a)),
                              serialize.load(torch.CharStorage():string(b)))
            end)
         return true
      end)
end

-- Sort the vector asynchronously
function Vector_:sortAsync(compare)
   return self.vector:writeAsync(
      function (vector)
         vector:sort(
            function (a, b)
               return compare(serialize.load(torch.CharStorage():string(a)),
                              serialize.load(torch.CharStorage():string(b)))
            end)
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
      end, true
   else
      return function() end, false
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
      end, true
   else
      return function() end, false
   end
end

-- Convert to string
function Vector_:toString()
   return self.vector:read(
      function (vector)
         return tostring(vector)
      end)
end

-- Convert to string asynchronously
function Vector_:toStringAsync()
   return self.vector:readAsync(
      function (vector)
         return tostring(vector)
      end)
end

-- The index operator
function Vector_:__index(index)
   if type(index) == 'number' then
      return self:get(index)
   else
      local method = rawget(Vector_, index)
      if method then
         return method
      else
         error('Invalid key (number) or method name')
      end
   end
end

-- The new index operator
function Vector_:__newindex(index, value)
   if type(index) == 'number' then
      self:set(index, value)
   else
      rawset(self, index, value)
   end
end

-- Array iterator operator
function Vector_:__ipairs()
   return self:iterator()
end

-- Table iterator operator
function Vector_:__pairs()
   return self:__ipairs()
end

-- Serialization of this object
function Vector_:__write(f)
   f:writeObject(self.vector)
   f:writeObject(self.size_hint)
   f:writeObject(self.mutex:id())
   f:writeObject(self.inserted_condition:id())
   f:writeObject(self.removed_condition:id())
end

-- Deserialization of this object
function Vector_:__read(f)
   self.vector = f:readObject()
   self.size_hint = f:readObject()
   self.mutex = threads.Mutex(f:readObject())
   self.inserted_condition = threads.Condition(f:readObject())
   self.removed_condition = threads.Condition(f:readObject())
end

-- Return the class, not the metatable
return tunnel.Vector
