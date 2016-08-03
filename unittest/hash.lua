--[[
Unittest for hash
Copyright 2016 Xiang Zhang
--]]

local Block = require('tunnel.block')
local Hash = require('tunnel.hash')
local Printer = require('tunnel.printer')

-- A Logic Named Joe
local joe = {}

function joe.main()
   if joe.init then
      print('Initializing testing environment')
      joe:init()
   end
   for name, func in pairs(joe) do
      if type(name) == 'string' and type(func) == 'function'
      and name:match('[%g]+Test') then
         print('\nExecuting '..name)
         func(joe)
      end
   end
end

function joe:init()
   local hash = Hash()
   local printer = Printer()
   self.hash = hash
   self.printer = printer
end

function joe:getSetTest()
   -- 2 synchronous get threads
   local sync_get_block = Block(2)
   sync_get_block:add(self.printer, self.hash)
   sync_get_block:run(self:syncGetJob())

   -- 3 synchronous set threads
   local sync_set_block = Block(3)
   sync_set_block:add(self.printer, self.hash)
   sync_set_block:run(self:syncSetJob())

   -- 2 asynchronous get threads
   local async_get_block = Block(2)
   async_get_block:add(self.printer, self.hash)
   async_get_block:run(self:asyncGetJob())

   -- 3 asynchronous set threads
   local async_set_block = Block(3)
   async_set_block:add(self.printer, self.hash)
   async_set_block:run(self:asyncSetJob())

   -- 1 synchronous iterator threads
   local sync_iterator_block = Block(1)
   sync_iterator_block:add(self.printer, self.hash)
   sync_iterator_block:run(self:syncIteratorJob())

   -- 1 synchronous iterator threads
   local async_iterator_block = Block(1)
   async_iterator_block:add(self.printer, self.hash)
   async_iterator_block:run(self:asyncIteratorJob())

   sync_get_block:synchronize()
   sync_set_block:synchronize()
   async_get_block:synchronize()
   async_set_block:synchronize()
   sync_iterator_block:synchronize()
   async_iterator_block:synchronize()
end

function joe:readWriteTest()
   -- 2 synchronous read threads
   local sync_read_block = Block(2)
   sync_read_block:add(self.printer, self.hash)
   sync_read_block:run(self:syncReadJob())

   -- 3 synchronous write threads
   local sync_write_block = Block(3)
   sync_write_block:add(self.printer, self.hash)
   sync_write_block:run(self:syncWriteJob())

   -- 2 asynchronous read threads
   local async_read_block = Block(2)
   async_read_block:add(self.printer, self.hash)
   async_read_block:run(self:asyncReadJob())

   -- 3 asynchronous write threads
   local async_write_block = Block(3)
   async_write_block:add(self.printer, self.hash)
   async_write_block:run(self:asyncWriteJob())

   -- 1 synchronous iterator threads
   local sync_iterator_block = Block(1)
   sync_iterator_block:add(self.printer, self.hash)
   sync_iterator_block:run(self:syncIteratorJob())

   -- 1 synchronous iterator threads
   local async_iterator_block = Block(1)
   async_iterator_block:add(self.printer, self.hash)
   async_iterator_block:run(self:asyncIteratorJob())

   sync_read_block:synchronize()
   sync_write_block:synchronize()
   async_read_block:synchronize()
   async_write_block:synchronize()
   sync_iterator_block:synchronize()
   async_iterator_block:synchronize()
end

function joe:syncGetJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 20000 + __threadid *1000)
      for i = 1, 30 do
         local key = tostring(math.random(100))
         local value = hash[key]
         printer('sync_get', __threadid, i, key, tostring(value))
         ffi.C.sleep(2)
      end
   end
end

function joe:syncSetJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 10000 + __threadid * 1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value = 10000 + __threadid * 1000 + i
         hash[key] = value
         printer('sync_set', __threadid, i, key, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncGetJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 40000 + __threadid *1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value, status = hash:getAsync(key)
         if status == true then
            printer('async_get', __threadid, i, key, tostring(value))
         else
            printer('async_get', __threadid, i, key, 'blocked')
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncSetJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 30000 + __threadid * 1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value = 20000 + __threadid * 1000 + i
         local status = hash:setAsync(key, value)
         if status == true then
            printer('async_set', __threadid, i, key, value)
         else
            printer('async_set', __threadid, i, key, 'blocked')
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:syncReadJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 40000 + __threadid *1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value, status = hash:read(
            key, function (value) return value, true end)
         if status == true then
            printer('sync_read', __threadid, i, key, tostring(value))
         else
            printer('sync_read', __threadid, i, key, 'blocked')
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:syncWriteJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 30000 + __threadid * 1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value = 20000 + __threadid * 1000 + i
         local status, value = hash:write(
            key, function (old_value) return value end)
         if status == true then
            printer('sync_write', __threadid, i, key, value)
         else
            printer('sync_write', __threadid, i, key, 'blocked')
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncReadJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 40000 + __threadid *1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value, status = hash:readAsync(
            key, function (value) return value, true end)
         if status == true then
            printer('async_read', __threadid, i, key, tostring(value))
         else
            printer('async_read', __threadid, i, key, 'blocked')
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncWriteJob()
   return function (printer, hash)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 30000 + __threadid * 1000)
      for i = 1, 60 do
         local key = tostring(math.random(100))
         local value = 20000 + __threadid * 1000 + i
         local status, value = hash:writeAsync(
            key, function (old_value) return value end)
         if status == true then
            printer('async_write', __threadid, i, key, value)
         else
            printer('async_write', __threadid, i, key, 'blocked')
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:syncIteratorJob()
   return function (printer, hash)
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      for i = 1, 5 do
         for key, value in pairs(hash) do
            printer('sync_iterator', __threadid, i, key, value)
         end
         ffi.C.sleep(12)
      end
   end
end

function joe:asyncIteratorJob()
   return function (printer, hash)
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      for i = 1, 5 do
         local iterator, status = hash:iteratorAsync()
         if status == true then
            for key, value in iterator do
               printer('async_iterator', __threadid, i, key, value)
            end
         else
            printer('async_iterator', __threadid, i, 'blocked')
         end
         ffi.C.sleep(12)
      end
   end
end

joe.main()
return joe
