--[[
Unittest for counter
Copyright 2016 Xiang Zhang
--]]

local Counter = require('tunnel.counter')

local Block = require('tunnel.block')
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
   local counter = Counter()
   local printer = Printer()
   self.counter = counter
   self.printer = printer
   self.printer('Counter initialized', counter:get())
end

function joe:counterTest()
   -- 2 synchronous increase threads
   local sync_increase_block = Block(2)
   sync_increase_block:add(self.printer, self.counter)
   sync_increase_block:run(self.syncIncreaseJob())

   -- 2 synchronous decrease threads
   local sync_decrease_block = Block(2)
   sync_decrease_block:add(self.printer, self.counter)
   sync_decrease_block:run(self.syncDecreaseJob())

   -- 2 asynchronous increase threads
   local async_increase_block = Block(2)
   async_increase_block:add(self.printer, self.counter)
   async_increase_block:run(self.asyncIncreaseJob())

   -- 2 asynchronous decrease threads
   local async_decrease_block = Block(2)
   async_decrease_block:add(self.printer, self.counter)
   async_decrease_block:run(self.asyncDecreaseJob())

   -- 2 synchronous get threads
   local sync_get_block = Block(2)
   sync_get_block:add(self.printer, self.counter)
   sync_get_block:run(self.syncGetJob())

   -- 2 synchronous set threads
   local sync_set_block = Block(2)
   sync_set_block:add(self.printer, self.counter)
   sync_set_block:run(self.syncSetJob())

   -- 2 asynchronous get threads
   local async_get_block = Block(2)
   async_get_block:add(self.printer, self.counter)
   async_get_block:run(self.asyncGetJob())

   -- 2 asynchronous get threads
   local async_set_block = Block(2)
   async_set_block:add(self.printer, self.counter)
   async_set_block:run(self.asyncSetJob())
end

function joe:syncIncreaseJob()
   return function (printer, counter)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 10000 + __threadid * 1000)
      for i = 1, 60 do
         local step = math.random(10)
         local value = counter:increase(step)
         printer('sync_increase', __threadid, step, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:syncDecreaseJob()
   return function (printer, counter)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 20000 + __threadid * 1000)
      for i = 1, 60 do
         local step = math.random(10)
         local value = counter:decrease(step)
         printer('sync_decrease', __threadid, step, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncIncreaseJob()
   return function (printer, counter)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 30000 + __threadid * 1000)
      for i = 1, 60 do
         local step = math.random(10)
         local value = counter:increaseAsync(step)
         printer('async_increase', __threadid, step, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncDecreaseJob()
   return function (printer, counter)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 40000 + __threadid * 1000)
      for i = 1, 60 do
         local step = math.random(10)
         local value = counter:decreaseAsync(step)
         printer('async_decrease', __threadid, step, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:syncGetJob()
   return function (printer, counter)
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      for i = 1, 60 do
         local value = counter:get()
         printer('sync_get', __threadid, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:syncSetJob()
   return function (printer, counter)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 50000 + __threadid * 1000)
      for i = 1, 60 do
         local value = math.random(10)
         value = counter:set(value)
         printer('sync_set', __threadid, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncGetJob()
   return function (printer, counter)
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      for i = 1, 60 do
         local value = counter:getAsync()
         printer('async_get', __threadid, value)
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncSetJob()
   return function (printer, counter)
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      math.randomseed(os.time() + 60000 + __threadid * 1000)
      for i = 1, 60 do
         local value = math.random(10)
         value = counter:setAsync(value)
         printer('async_set', __threadid, value)
         ffi.C.sleep(1)
      end
   end
end

joe.main()
return joe
