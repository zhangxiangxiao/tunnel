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
   -- Create a block 10 threads
   local block = threads.Threads(10, self:threadInit())
   block:specific(true)

   -- 3 synchronous readers
   for i = 1, 3 do
      local job = self:syncReaderJob()
      block:addjob(i, job)
   end

   -- 2 asynchronous readers
   for i = 4, 5 do
      local job = self:asyncReaderJob()
      block:addjob(i, job)
   end

   -- 2 synchronous writers
   for i = 6, 7 do
      local job = self:syncWriterJob()
      block:addjob(i, job)
   end

   -- 3 asynchronous writers
   for i = 8, 10 do
      local job = self:asyncWriterJob()
      block:addjob(i, job)
   end
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
      local ffi = require 'ffi'
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
      local ffi = require 'ffi'
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
      local ffi = require "ffi"
      ffi.cdef "unsigned int sleep(unsigned int seconds);"
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
         if not atomic_data:write_async(callback) then
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
      local ffi = require 'ffi'
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
         if not atomic_data:read_async(callback) then
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
