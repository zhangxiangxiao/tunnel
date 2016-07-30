--[[
Unittest for Atomic
Copyright 2016 Xiang Zhang
--]]

local Atomic = require('tunnel.atomic')

local threads = require('threads')
local torch = require('torch')

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
   local data = torch.DoubleTensor(1)
   local atomic_data = Atomic(data)
   self.atomic_data = atomic_data
   self.print_mutex = threads.Mutex()
end

function joe:readwriteTest()
   -- 3 synchronous readers
   local sync_reader_block = threads.Threads(3, self:threadInit())
   sync_reader_block:specific(true)
   for i = 1, 3 do
      local job = self:syncReaderJob()
      sync_reader_block:addjob(i, job)
   end

   -- 2 asynchronous readers
   local async_reader_block = threads.Threads(2, self:threadInit())
   async_reader_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncReaderJob()
      async_reader_block:addjob(i, job)
   end

   -- 2 synchronous writers
   local sync_writer_block = threads.Threads(2, self:threadInit())
   sync_writer_block:specific(true)
   for i = 1, 2 do
      local job = self:syncWriterJob()
      sync_writer_block:addjob(i, job)
   end

   -- 3 asynchronous writers
   local async_writer_block = threads.Threads(3, self:threadInit())
   async_writer_block:specific(true)
   for i = 1, 3 do
      local job = self:asyncWriterJob()
      async_writer_block:addjob(i, job)
   end

   sync_reader_block:terminate()
   async_reader_block:terminate()
   sync_writer_block:terminate()
   async_writer_block:terminate()
end

function joe:threadInit()
   return function()
      local torch = require('torch')
      local Atomic = require('tunnel.atomic')
   end
end

function joe:syncWriterJob()
   local print_mutex_id = self.print_mutex:id()
   local atomic_data = self.atomic_data
   return function()
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local threads = require('threads')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 10 do
         local callback = function (data)
            print_mutex:lock()
            print('sync_writer', __threadid, i, data[1], __threadid * 1000 + i)
            data[1] =  __threadid * 1000 + i
            print_mutex:unlock()
            return true
         end
         if not atomic_data:write(callback) then
            print_mutex:lock()
            print('sync_writer', __threadid, i, 'writer blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(5)
      end
   end
end

function joe:syncReaderJob()
   local print_mutex_id = self.print_mutex:id()
   local atomic_data = self.atomic_data
   return function()
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local threads = require('threads')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 10 do
         local callback = function (data)
            print_mutex:lock()
            print('sync_reader', __threadid, i, data[1])
            print_mutex:unlock()
            return true
         end
         if not atomic_data:read(callback) then
            print_mutex:lock()
            print('sync_reader', __threadid, i, 'reader blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(5)
      end
   end
end

function joe:asyncWriterJob()
   local print_mutex_id = self.print_mutex:id()
   local atomic_data = self.atomic_data
   return function()
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local threads = require('threads')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 40 do
         local callback = function (data)
            print_mutex:lock()
            print('async_writer', __threadid, i, data[1], __threadid * 1000 + i)
            data[1] =  __threadid * 1000 + i
            print_mutex:unlock()
            ffi.C.sleep(1)
            return true
         end
         if not atomic_data:writeAsync(callback) then
            print_mutex:lock()
            print('async_writer', __threadid, i, 'writer blocked')
            print_mutex:unlock()
            ffi.C.sleep(2)
         end
      end
   end
end

function joe:asyncReaderJob()
   local print_mutex_id = self.print_mutex:id()
   local atomic_data = self.atomic_data
   return function()
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local threads = require('threads')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 50 do
         local callback = function (data)
            print_mutex:lock()
            print('async_reader', __threadid, i, data[1])
            print_mutex:unlock()
            ffi.C.sleep(1)
            return true
         end
         if not atomic_data:readAsync(callback) then
            print_mutex:lock()
            print('async_reader', __threadid, i, 'reader blocked')
            print_mutex:unlock()
            ffi.C.sleep(1)
         end
      end
   end
end

joe.main()
return joe
