--[[
Multi-threaded reader-writer wrapper
Copyright 2016 Xiang Zhang
--]]

local ffi = require('ffi')
local serialize = require('threads.sharedserialize')
local threads = require('threads')
local torch = require('torch')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Atomic_ = torch.class('tunnel.Atomic')

-- Constructor
-- data: the data to be protected. Must be shared serializable.
function Atomic_:__init(data)
   self.data = data

   self.count = torch.LongTensor(2):fill(0)
   self.mutex = threads.Mutex()
   self.wrote_condition = threads.Condition()
   self.read_condition = threads.Condition()

   -- Lua 5.1 / LuaJIT garbage collection
   if newproxy then
      self.proxy = newproxy(true)
      getmetatable(self.proxy).__gc = function () self:__gc() end
   end

   return self
end

-- Synchronous exclusive writer
-- callback: a callback that writes in data
function Atomic_:write(callback)
   self.mutex:lock()
   while self.count[1] > 0 do
      self.wrote_condition:wait(self.mutex)
   end
   self.wrote_condition:signal()
   self.count[1] = self.count[1] + 1
 
   -- Waiting for other readers
   while self.count[2] > 0 do
      self.read_condition:wait(self.mutex)
   end
   self.read_condition:signal()
   self.mutex:unlock()

   -- Execute the write
   local status, result = self:pack(pcall(callback, self.data))

   -- Release the write
   self.mutex:lock()
   self.count[1] = self.count[1] - 1
   self.mutex:unlock()
   self.wrote_condition:signal()

   if status == false then
      error(unpack(result))
   end

   return unpack(result)
end

-- Synchrounous non-exclusive reader
-- callback: a callback that reads from data
function Atomic_:read(callback)
   self.mutex:lock()
   -- Waiting for other writers
   while self.count[1]  > 0 do
      self.wrote_condition:wait(self.mutex)
   end
   self.wrote_condition:signal()
   self.count[2] = self.count[2] + 1
   self.mutex:unlock()

   -- Execute the read
   local status, result = self:pack(pcall(callback, self.data))
   
   -- Release the read
   self.mutex:lock()
   self.count[2] = self.count[2] - 1
   self.mutex:unlock()
   self.read_condition:signal()

   if status == false then
      error(unpack(result))
   end

   return unpack(result)
end

-- Asynchronous exclusive writer
-- callback: a callback that writes in data
-- Return immediately if cannot write, since there are other readers or writers
function Atomic_:writeAsync(callback)
   -- Decide whether to write
   local decision  = false
   if self.count[1] == 0 and self.count[2] == 0 then
      self.mutex:lock()
      if self.count[1] == 0 and self.count[2] == 0 then
         self.count[1] = self.count[1] + 1
         decision = true
      end
      self.mutex:unlock()
   end

   if decision == true then
      -- Execute write
      local status, result = self:pack(pcall(callback, self.data))

      -- Release the write
      self.mutex:lock()
      self.count[1] = self.count[1] - 1
      self.mutex:unlock()
      self.wrote_condition:signal()

      if status == false then
         error(unpack(result))
      end

      return unpack(result)
   end
end

-- Asynchronous non-exclusive reader
-- callback: a callback and reads from data
-- Return immediately if cannot read, since there are other writers
function Atomic_:readAsync(callback)
   -- Decide whether to read
   local decision = false
   if self.count[1] == 0 then
      self.mutex:lock()
      if self.count[1] == 0 then
         self.count[2] = self.count[2] + 1
         decision = true
      end
      self.mutex:unlock()
   end

   if decision == true then
      -- Execute the read
      local status, result = self:pack(pcall(callback, self.data))

      -- Release the read
      self.mutex:lock()
      self.count[2] = self.count[2] - 1
      self.mutex:unlock()
      self.read_condition:signal()

      if status == false then
         error(unpack(result))
      end

      return unpack(result)
   end
end

-- Pack returned results into a table
function Atomic_:pack(status, ...)
   return status, {...}
end

-- Free allocated resources
function Atomic_:free()
   self.mutex:free()
   self.wrote_condition:free()
   self.read_condition:free()
end

-- This works for Lua 5.2, for Lua 5.1 / LuaJIT we depend on self.proxy
function Atomic_:__gc()
   self:free()
end

-- Serialization of this object
function Atomic_:__write(f)
   local data = serialize.save(self.data)
   f:writeObject(data)

   local count = serialize.save(self.count)
   f:writeObject(count)

   f:writeObject(self.mutex:id())
   f:writeObject(self.wrote_condition:id())
   f:writeObject(self.read_condition:id())
end

-- Deserialization of this object
function Atomic_:__read(f)
   local data = f:readObject()
   self.data = serialize.load(data)

   local count = f:readObject()
   self.count = serialize.load(count)

   self.mutex = threads.Mutex(f:readObject())
   self.wrote_condition = threads.Condition(f:readObject())
   self.read_condition = threads.Condition(f:readObject())

   -- Lua 5.1 / LuaJIT garbage collection
   if newproxy then
      self.proxy = newproxy(true)
      getmetatable(self.proxy).__gc = function () self:__gc() end
   end
end

-- Return the class, not the metatable Atomic_
return tunnel.Atomic
