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
   local vector = Vector(5)
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

   sync_insert_block:terminate()
   sync_remove_block:terminate()
   async_insert_block:terminate()
   async_remove_block:terminate()
   sync_iterator_block:terminate()
   async_iterator_block:terminate()
   sync_tostring_block:terminate()
   async_tostring_block:terminate()
end

function joe:pushPopTest()
   -- 3 synchronous pushFront threads
   local sync_pushfront_block = threads.Threads(3, self:threadInit())
   sync_pushfront_block:specific(true)
   for i = 1, 3 do
      local job = self:syncPushFrontJob()
      sync_pushfront_block:addjob(i, job)
   end

   -- 2 synchronous popFront threads
   local sync_popfront_block = threads.Threads(2, self:threadInit())
   sync_popfront_block:specific(true)
   for i = 1, 2 do
      local job = self:syncPopFrontJob()
      sync_popfront_block:addjob(i, job)
   end

   -- 3 asynchronous pushFront threads
   local async_pushfront_block = threads.Threads(3, self:threadInit())
   async_pushfront_block:specific(true)
   for i = 1, 3 do
      local job = self:asyncPushFrontJob()
      async_pushfront_block:addjob(i, job)
   end

   -- 2 asynchronous popFront threads
   local async_popfront_block = threads.Threads(2, self:threadInit())
   async_popfront_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncPopFrontJob()
      async_popfront_block:addjob(i, job)
   end

      -- 3 synchronous pushBack threads
   local sync_pushback_block = threads.Threads(3, self:threadInit())
   sync_pushback_block:specific(true)
   for i = 1, 3 do
      local job = self:syncPushBackJob()
      sync_pushback_block:addjob(i, job)
   end

   -- 2 synchronous popBack threads
   local sync_popback_block = threads.Threads(2, self:threadInit())
   sync_popback_block:specific(true)
   for i = 1, 2 do
      local job = self:syncPopBackJob()
      sync_popback_block:addjob(i, job)
   end

   -- 3 asynchronous pushBack threads
   local async_pushback_block = threads.Threads(3, self:threadInit())
   async_pushback_block:specific(true)
   for i = 1, 3 do
      local job = self:asyncPushBackJob()
      async_pushback_block:addjob(i, job)
   end

   -- 2 asynchronous popBack threads
   local async_popback_block = threads.Threads(2, self:threadInit())
   async_popback_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncPopBackJob()
      async_popback_block:addjob(i, job)
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

   sync_pushfront_block:terminate()
   sync_popfront_block:terminate()
   async_pushfront_block:terminate()
   async_popfront_block:terminate()
   sync_pushback_block:terminate()
   sync_popback_block:terminate()
   async_pushback_block:terminate()
   async_popback_block:terminate()
   sync_iterator_block:terminate()
   async_iterator_block:terminate()
   sync_tostring_block:terminate()
   async_tostring_block:terminate()
end

function joe:getSetTest()
   -- 3 synchronous insert threads
   local sync_insert_block = threads.Threads(3, self:threadInit())
   sync_insert_block:specific(true)
   for i = 1, 3 do
      local job = self:syncInsertJob()
      sync_insert_block:addjob(i, job)
   end

   -- 2 synchronous get threads
   local sync_get_block = threads.Threads(2, self:threadInit())
   sync_get_block:specific(true)
   for i = 1, 2 do
      local job = self:syncGetJob()
      sync_get_block:addjob(i, job)
   end

   -- 2 synchronous set threads
   local sync_set_block = threads.Threads(2, self:threadInit())
   sync_set_block:specific(true)
   for i = 1, 2 do
      local job = self:syncSetJob()
      sync_set_block:addjob(i, job)
   end

   -- 2 asynchronous get threads
   local async_get_block = threads.Threads(2, self:threadInit())
   async_get_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncGetJob()
      async_get_block:addjob(i, job)
   end

   -- 2 asynchronous set threads
   local async_set_block = threads.Threads(2, self:threadInit())
   async_set_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncSetJob()
      async_set_block:addjob(i, job)
   end

   -- 1 synchronous sort thread
   local sync_sort_block = threads.Threads(1, self:threadInit())
   sync_sort_block:specific(true)
   for i = 1, 1 do
      local job = self:syncSortJob()
      sync_sort_block:addjob(i, job)
   end

   -- 1 synchronous sort thread
   local async_sort_block = threads.Threads(1, self:threadInit())
   async_sort_block:specific(true)
   for i = 1, 1 do
      local job = self:asyncSortJob()
      async_sort_block:addjob(i, job)
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

   sync_insert_block:terminate()
   sync_get_block:terminate()
   sync_set_block:terminate()
   async_get_block:terminate()
   async_set_block:terminate()
   sync_sort_block:terminate()
   async_sort_block:terminate()
   sync_iterator_block:terminate()
   async_iterator_block:terminate()
end

function joe:readWriteTest()
   -- 3 synchronous insert threads
   local sync_insert_block = threads.Threads(3, self:threadInit())
   sync_insert_block:specific(true)
   for i = 1, 3 do
      local job = self:syncInsertJob()
      sync_insert_block:addjob(i, job)
   end

   -- 2 synchronous read threads
   local sync_read_block = threads.Threads(2, self:threadInit())
   sync_read_block:specific(true)
   for i = 1, 2 do
      local job = self:syncReadJob()
      sync_read_block:addjob(i, job)
   end

   -- 2 synchronous write threads
   local sync_write_block = threads.Threads(2, self:threadInit())
   sync_write_block:specific(true)
   for i = 1, 2 do
      local job = self:syncWriteJob()
      sync_write_block:addjob(i, job)
   end

   -- 2 asynchronous read threads
   local async_read_block = threads.Threads(2, self:threadInit())
   async_read_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncReadJob()
      async_read_block:addjob(i, job)
   end

   -- 2 asynchronous write threads
   local async_write_block = threads.Threads(2, self:threadInit())
   async_write_block:specific(true)
   for i = 1, 2 do
      local job = self:asyncWriteJob()
      async_write_block:addjob(i, job)
   end

   -- 1 synchronous sort thread
   local sync_sort_block = threads.Threads(1, self:threadInit())
   sync_sort_block:specific(true)
   for i = 1, 1 do
      local job = self:syncSortJob()
      sync_sort_block:addjob(i, job)
   end

   -- 1 synchronous sort thread
   local async_sort_block = threads.Threads(1, self:threadInit())
   async_sort_block:specific(true)
   for i = 1, 1 do
      local job = self:asyncSortJob()
      async_sort_block:addjob(i, job)
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

   sync_insert_block:terminate()
   sync_read_block:terminate()
   sync_write_block:terminate()
   async_read_block:terminate()
   async_write_block:terminate()
   sync_sort_block:terminate()
   async_sort_block:terminate()
   sync_iterator_block:terminate()
   async_iterator_block:terminate()
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
         local status = true
         local iterator = pairs(vector)
         if status == true then
            print_mutex:lock()
            io.write('sync_iterator', '\t',  __threadid, '\t', i, '\t{')
            for index, value in iterator do
               io.write(index, ':', tostring(value), ',')
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
               io.write(index, ':', tostring(value), ',')
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
         local vector_string = tostring(vector)
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

function joe:syncPushFrontJob()
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
      for i = 1, 30 do
         local value = 30000 + __threadid * 1000 + i
         local status = vector:pushFront(value)
         if status == true then
            print_mutex:lock()
            print('sync_pushfront', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_pushfront', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:syncPopFrontJob()
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
      for i = 1, 30 do
         local value, status = vector:popFront()
         if status == true then
            print_mutex:lock()
            print('sync_popfront', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_popfront', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:asyncPushFrontJob()
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
         local value = 40000 + __threadid * 1000 + i
         local status = vector:pushFrontAsync(value)
         if status == true then
            print_mutex:lock()
            print('async_pushfront', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_pushfront', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(6)
      end
   end
end

function joe:asyncPopFrontJob()
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
      for i = 1, 30 do
         local value, status = vector:popFrontAsync()
         if status == true then
            print_mutex:lock()
            print('async_popfront', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_popfront', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:syncPushBackJob()
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
      for i = 1, 30 do
         local value = 50000 + __threadid * 1000 + i
         local status = vector:pushBack(value)
         if status == true then
            print_mutex:lock()
            print('sync_pushback', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_pushback', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:syncPopBackJob()
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
      for i = 1, 30 do
         local value, status = vector:popBack()
         if status == true then
            print_mutex:lock()
            print('sync_popback', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_popback', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:asyncPushBackJob()
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
         local value = 40000 + __threadid * 1000 + i
         local status = vector:pushBackAsync(value)
         if status == true then
            print_mutex:lock()
            print('async_pushback', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_pushback', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(6)
      end
   end
end

function joe:asyncPopBackJob()
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
         local value, status = vector:popBackAsync()
         if status == true then
            print_mutex:lock()
            print('async_popback', __threadid, i, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_popback', __threadid, i, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:syncGetJob()
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
      for i = 1, 30 do
         local index = math.random(10)
         local value = vector[index]
         local status = true
         if status == true then
            print_mutex:lock()
            print('sync_get', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_get', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:syncSetJob()
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
      for i = 1, 60 do
         local index = math.random(10)
         local value = 50000 + __threadid * 1000 + i
         vector[index] = value
         local status = true
         if status == true then
            print_mutex:lock()
            print('sync_set', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_set', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncGetJob()
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
         local value, status = vector:getAsync(index)
         if status == true then
            print_mutex:lock()
            print('async_get', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_get', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:asyncSetJob()
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
      for i = 1, 60 do
         local index = math.random(10)
         local value = 60000 + __threadid * 1000 + i
         local status, old_value = vector:setAsync(index, value)
         if status == true then
            print_mutex:lock()
            print('async_set', __threadid, i, index, value, old_value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print(
               'async_set', __threadid, i, index, value, old_value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:syncSortJob()
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
         local status = vector:sort(
            function (a, b)
               if a == nil then
                  return true
               elseif b == nil then
                  return false
               end
               return a < b
            end)
         if status == true then
            print_mutex:lock()
            print('sync_sort', __threadid)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_sort', __threadid, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:asyncSortJob()
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
         local status = vector:sortAsync(
            function (a, b)
               if a == nil then
                  return true
               elseif b == nil then
                  return false
               end
               return a < b
            end)
         if status == true then
            print_mutex:lock()
            print('async_sort', __threadid)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_sort', __threadid, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(3)
      end
   end
end

function joe:syncReadJob()
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
      for i = 1, 30 do
         local index = math.random(10)
         local status, value = vector:read(
            index, function (value) return true, value end)
         if status == true then
            print_mutex:lock()
            print('sync_read', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_read', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:syncWriteJob()
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
      for i = 1, 60 do
         local index = math.random(10)
         local value = 50000 + __threadid * 1000 + i
         local status, value = vector:write(
            index, function (old_value) return value end)
         if status == true then
            print_mutex:lock()
            print('sync_write', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('sync_write', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(1)
      end
   end
end

function joe:asyncReadJob()
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
      for i = 1, 30 do
         local index = math.random(10)
         local status, value = vector:readAsync(
            index, function (value) return true, value end)
         if status == true then
            print_mutex:lock()
            print('async_read', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_read', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(2)
      end
   end
end

function joe:asyncWriteJob()
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
      for i = 1, 60 do
         local index = math.random(10)
         local value = 50000 + __threadid * 1000 + i
         local status, value = vector:writeAsync(
            index, function (old_value) return value end)
         if status == true then
            print_mutex:lock()
            print('async_write', __threadid, i, index, value)
            print_mutex:unlock()
         else
            print_mutex:lock()
            print('async_write', __threadid, i, index, value, 'blocked')
            print_mutex:unlock()
         end
         ffi.C.sleep(1)
      end
   end
end

joe.main()
return joe
