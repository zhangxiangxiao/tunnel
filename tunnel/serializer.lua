--[[
Data serialization for Tunnel
Copyright Xiang Zhang 2016
--]]

local ffi = require('ffi')
local serialize = require('threads.sharedserialize')
local tds = require('tds')
local torch = require('torch')

tunnel = tunnel or {}

local Serializer_ = torch.class('tunnel.Serializer')

Serializer_.state = nil
local STATE = {WRITE = 1, READ = 2, RETAIN = 3}

-- Serialize function
function Serializer_:save(object)
   local state = self.setWrite()
   local f = torch.MemoryFile()
   f:binary()
   f:writeObject(object)
   local storage = f:storage()
   f:close()
   self.setState(state)
   return storage
end

-- Load function
function Serializer_:load(storage)
   local state = self.setRead()
   local f = torch.MemoryFile(storage)
   f:binary()
   local object = f:readObject()
   f:close()
   self.setState(state)
   return object
end

-- Retrain-and-load function
function Serializer_:retain(storage)
   local state = self.setRetain()
   local f = torch.MemoryFile(storage)
   f:binary()
   local object = f:readObject()
   f:close()
   self.setState(state)
   return object
end

function Serializer_.setWrite()
   return Serializer_.setState(STATE.WRITE)
end

function Serializer_.setRead()
   return Serializer_.setState(STATE.READ)
end

function Serializer_.setRetain()
   return Serializer_.setState(STATE.RETAIN)
end

function Serializer_.setState(state)
   local old_state = Serializer_.state
   if Serializer_.state ~= state then
      if Serializer_.state ~= nil then
         Serializer_.swap[Serializer_.state]()
      end
      if state ~= nil then
         Serializer_.swap[state]()
      end
      Serializer_.state = state
   end
   return old_state
end

function Serializer_.swapWrite()
   for name, metatable in pairs(Serializer_.metatables) do
      local current = torch.getmetatable(name)
      if current then
         current.__factory, metatable.factory =
            metatable.factory, current.__factory
         current.__write, metatable.write =
            metatable.write, current.__write
         current.write, metatable.__write =
            metatable.__write, current.write
      end
   end
end

-- Swap metatables for reading
function Serializer_.swapRead()
   for name, metatable in pairs(Serializer_.metatables) do
      local current = torch.getmetatable(name)
      if current then
         current.__factory, metatable.factory =
            metatable.factory, current.__factory
         current.__read, metatable.read =
            metatable.read, current.__read
         current.read, metatable.__read =
            metatable.__read, current.read
      end
   end
end

-- Swap metatables for retained reading
function Serializer_.swapRetain()
   for name, metatable in pairs(Serializer_.metatables) do
      local current = torch.getmetatable(name)
      if current then
         current.__factory, metatable.factory =
            metatable.factory, current.__factory
         current.__read, metatable.retain =
            metatable.retain, current.__read
         current.read, metatable.__retain =
            metatable.__retain, current.read
      end
   end
end

-- Swap tables based on state
Serializer_.swap = {}
Serializer_.swap[STATE.WRITE] = Serializer_.swapWrite
Serializer_.swap[STATE.READ] = Serializer_.swapRead
Serializer_.swap[STATE.RETAIN] = Serializer_.swapRetain

-- Serialize pointer function
function Serializer_.savePointer(object, f)
   f:writeLong(torch.pointer(object))
end

-- Deserialization pointer function
function Serializer_.loadPointer(f)
   return f:readLong()
end

-- Serializer metatatables for different data-types
Serializer_.metatables = {}

Serializer_.metatables['tds.Hash'] = {}
Serializer_.metatables['tds.Hash']['factory'] = function(f)
   local object = Serializer_.loadPointer(f)
   object = ffi.cast('tds_hash&', object)
   ffi.gc(object, tds.C.tds_hash_free)
   return object
end
Serializer_.metatables['tds.Hash']['write'] = function(object, f)
   Serializer_.savePointer(object, f)
   tds.C.tds_hash_retain(object)
end
Serializer_.metatables['tds.Hash']['read'] = function(object, f)
end
Serializer_.metatables['tds.Hash']['retain'] = function(object, f)
   tds.C.tds_hash_retain(object)
end

Serializer_.metatables['tds.Vec'] = {}
Serializer_.metatables['tds.Vec']['factory'] = function(f)
   local object = Serializer_.loadPointer(f)
   object = ffi.cast('tds_vec&', object)
   ffi.gc(object, tds.C.tds_vec_free)
   return object
end
Serializer_.metatables['tds.Vec']['write'] = function(object, f)
   Serializer_.savePointer(object, f)
   tds.C.tds_vec_retain(object)
end
Serializer_.metatables['tds.Vec']['read'] = function(object, f)
end
Serializer_.metatables['tds.Vec']['retain'] = function(object, f)
   tds.C.tds_vec_retain(object)
end

Serializer_.metatables['tds.AtomicCounter'] = {}
Serializer_.metatables['tds.AtomicCounter']['factory'] = function(f)
   local object = Serializer_.loadPointer(f)
   object = ffi.cast('tds_atomic_counter&', object)
   ffi.gc(object, tds.C.tds_atomic_free)
   return object
end
Serializer_.metatables['tds.AtomicCounter']['write'] = function (object, f)
   Serializer_.savePointer(object, f)
   tds.C.tds_atomic_retain(object)
end
Serializer_.metatables['tds.AtomicCounter']['read'] = function(object, f)
end
Serializer_.metatables['tds.AtomicCounter']['retain'] = function (object, f)
   tds.C.tds_atomic_retain(object)
end

Serializer_.metatables['torch.Allocator'] = {}
Serializer_.metatables['torch.Allocator']['factory'] = function(f)
   local object = Serializer_.loadPointer(f)
   object = torch.pushudata(object, name)
   return object
end
Serializer_.metatables['torch.Allocator']['write'] = function(object, f)
   Serializer_.savePointer(object, f)
end
Serializer_.metatables['torch.Allocator']['read'] = function(object, f)
end
Serializer_.metatables['torch.Allocator']['retain'] = function(object, f)
end

for _, name in ipairs{
   'torch.ByteTensor',
   'torch.CharTensor',
   'torch.ShortTensor',
   'torch.IntTensor',
   'torch.LongTensor',
   'torch.FloatTensor',
   'torch.DoubleTensor',
   'torch.CudaTensor',
   'torch.ByteStorage',
   'torch.CharStorage',
   'torch.ShortStorage',
   'torch.IntStorage',
   'torch.LongStorage',
   'torch.FloatStorage',
   'torch.DoubleStorage',
   'torch.CudaStorage'} do

   Serializer_.metatables[name] = {}
   Serializer_.metatables[name]['factory'] = function(f)
      local object = Serializer_.loadPointer(f)
      object = torch.pushudata(object, name)
      return object
   end
   Serializer_.metatables[name]['write'] = function(object, f)
      Serializer_.savePointer(object, f)
      object:retain()
   end
   Serializer_.metatables[name]['read'] = function(object, f)
   end
   Serializer_.metatables[name]['retain'] = function(object, f)
      object:retain()
   end
end

return tunnel.Serializer
