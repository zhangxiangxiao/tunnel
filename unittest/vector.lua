--[[
Unittest for vector
Copyright 2016 Xiang Zhang
--]]

local Vector = require('tunnel.vector')

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
   local vector = Vector()
   self.vector = vector
   self.print_mutex = threads.Mutex()
end

function joe:insertRemoveTest()
   -- 3 synchronous insert threads
   local sync_insert_block = threads.Threads(3, self:threadInit())
   sync_insert_block:specific(true)
   for i = 1, 3 do
      local job = self:syncInsertJob()
      sync_insert_block:addjob(i, job)
   end

   -- 2 synchronous remove threads
   local sync_remove_block = threads.Threads(2, self:threadInit())
   sync_remove_block:specific(true)
   for i = 1, 2 do
      local job = self:syncRemoveJob()
      sync_remove_block:addjob(i, job)
   end

   -- 3 asynchronous insert threads
   local async_insert_block = threads.Threads(3, self:threadInit())
   async_insert_block:specific(true)
   for i = 1, 3 do
      local job = self:asyncInsertJob()
      async_insert_block:addjob(i, job)
   end

   -- 2 asynchronous remove threads
   local async_remove_block = threads.Threads(2, self:threadInit())
   async_remove_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncRemoveJob()
      async_remove_block:addjob(i, job)
   end

   -- 1 synchronous iterator thread
   local sync_iterator_block = threads.Threads(1, self:threadInit())
   sync_iterator_block:specific(true)
   for i = 1, 1 do
      local job = self:syncIteratorJob()
      sync_iterator_block:addjob(i, job)
   end

   -- 1 asynchronous iterator thread
   local async_iterator_block = threads.Threads(1, self:threadInit())
   async_iterator_block:specific(true)
   for i = 1, 1 do
      local job = self:asyncIteratorJob()
      async_iterator_block:addjob(i, job)
   end

   -- 1 synchronous tostring thread
   local sync_tostring_block = threads.Threads(1, self:threadInit())
   sync_tostring_block:specific(true)
   for i = 1, 1 do
      local job = self:syncToStringJob()
      sync_tostring_block:addjob(i, job)
   end

   -- 1 Asynchronous tostring thread
   local async_tostring_block = threads.Threads(1, self:threadInit())
   async_tostring_block:specific(true)
   for i = 1, 1 do
      local job = self:asyncToStringJob()
      async_tostring_block:addjob(i, job)
   end
end

function joe:pushPopTest()
end

function joe:threadInit()
   return function()
      local torch = require('torch')
      local Vector = require('tunnel.vector')
   end
end

function joe:syncInsertJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 10 do
         local index = math.random(3)
         local value = 10000 + __threadid * 1000 + i
         local status = vector:insert(index, value)
         if status == true then
            print_mutex:lock()
            print('sync_insert', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_insert', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(6)
      end
   end
end

function joe:syncRemoveJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 20 do
         local index = math.random(10)
         local value, status = vector:remove(index)
         if status == true then
            print_mutex:lock()
            print('sync_remove', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_remove', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:asyncInsertJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 10 do
         local index = math.random(3)
         local value = 20000 + __threadid * 1000 + i
         local status = vector:insertAsync(index, value)
         if status == true then
            print_mutex:lock()
            print('async_insert', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_insert', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(6)
      end
   end
end

function joe:asyncRemoveJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 20 do
         local index = math.random(10)
         local value, status = vector:removeAsync(index)
         if status == true then
            print_mutex:lock()
            print('async_remove', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_remove', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:syncIteratorJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local io = require('io')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 30 do
         local iterator, status = vector:iterator()
         if status == true then
            print_mutex:lock()
            io.write('sync_iterator', '\t',  __threadid, '\t', i, '\t{')
            for index, value in iterator do
               io.write(index, ':', value, ',')
            end
            io.write('}\n')
            io.flush()
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_iterator', __threadid, i, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:asyncIteratorJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local io = require('io')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 20 do
         local iterator, status = vector:iteratorAsync()
         if status == true then
            print_mutex:lock()
            io.write('async_iterator', '\t',  __threadid, '\t', i, '\t{')
            for index, value in iterator do
               io.write(index, ':', value, ',')
            end
            io.write('}\n')
            io.flush()
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_iterator', __threadid, i, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:syncToStringJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 12 do
         local vector_string = vector:toString()
         if vector_string ~= nil then
            print_mutex:lock()
            print('sync_tostring', __threadid, i,
                  vector_string:gsub('\n', ','):gsub('    ',''))
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_tostring', __threadid, i, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(5)
      end
   end
end

function joe:asyncToStringJob()
   local print_mutex_id = self.print_mutex:id()
   local vector = self.vector
   return function()
      local ffi = require('ffi')
      local math = require('math')
      local os = require('os')
      local threads = require('threads')

      math.randomseed(os.time() + __threadid)
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      local print_mutex = threads.Mutex(print_mutex_id)
      for i = 1, 12 do
         local vector_string = vector:toStringAsync()
         if vector_string ~= nil then
            print_mutex:lock()
            print('async_tostring', __threadid, i,
                  vector_string:gsub('\n', ','):gsub('    ',''))
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_tostring', __threadid, i, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(5)
      end
   end
end

joe.main()
return joe
