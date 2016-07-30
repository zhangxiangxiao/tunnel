--[[
Unittest for Block
Copyright 2016 Xiang Zhang
--]]

local Block = require('tunnel.block')

local threads = require('threads')
local torch = require('torch')

local Atomic = require('tunnel.atomic')
local Vector = require('tunnel.vector')

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
   if joe.free then
      print('Freeing testing environment')
      joe:free()
   end
end

function joe:dummyTest()
   local print_mutex = threads.Mutex()
   local print_mutex_id = print_mutex:id()

   print('Creating a block of 5 threads')
   local init_job = function ()
      local threads = require('threads')

      local print_mutex = threads.Mutex(print_mutex_id)
      print_mutex:lock()
      print('init_job', __threadid)
      print_mutex:unlock()
      print_mutex:free()
   end
   local block = Block(5, init_job)

   print('Executing a first job for the threads')
   local first_job = function()
      local ffi = require('ffi')
      local threads = require('threads')

      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      ffi.C.sleep(1)

      local print_mutex = threads.Mutex(print_mutex_id)
      print_mutex:lock()
      print('first_job', __threadid)
      print_mutex:unlock()
      print_mutex:free()
      return 'first job return message', __threadid
   end
   local run_id = block:run(first_job)
   print('Got run id: '..run_id)

   print('Synchronize the threads')
   local result, status = block:synchronize()
   print('Getting execution results')
   for index, value in ipairs(result) do
      print(status[index], unpack(value))
   end

   print('Executing a second job for the threads')
   local second_job = function()
      local ffi = require('ffi')
      local threads = require('threads')

      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      ffi.C.sleep(1)

      local print_mutex = threads.Mutex(print_mutex_id)
      print_mutex:lock()
      print('second_job', __threadid)
      print_mutex:unlock()
      print_mutex:free()
      return 'second job return message', __threadid
   end
   local run_id = block:run(second_job)
   print('Got run id: '..run_id)

   print('Synchronize the threads')
   local result, status = block:synchronize()
   print('Getting execution results')
   for index, value in ipairs(result) do
      print(status[index], unpack(value))
   end

   print('Terminating the threads')
   local result, status = block:terminate()
end

function joe:errorTest()
   local print_mutex = threads.Mutex()
   local print_mutex_id = print_mutex:id()

   print('Creating a block of 5 threads')
   local init_job = function ()
      local threads = require('threads')

      local print_mutex = threads.Mutex(print_mutex_id)
      print_mutex:lock()
      print('init_job', __threadid)
      print_mutex:unlock()
      print_mutex:free()
   end
   local block = Block(5, init_job)

   print('Executing a first job for the threads')
   local first_job = function()
      local ffi = require('ffi')
      local threads = require('threads')

      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      ffi.C.sleep(1)

      local print_mutex = threads.Mutex(print_mutex_id)
      print_mutex:lock()
      print('first_job', __threadid)
      print_mutex:unlock()
      print_mutex:free()
      error('this is a test error for thread '..tostring(__threadid))
      return 'first job return message', __threadid
   end
   local run_id = block:run(first_job)
   print('Got run id: '..run_id)

   print('Executing a second job for the threads')
   local second_job = function()
      local ffi = require('ffi')
      local threads = require('threads')

      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      ffi.C.sleep(1)

      local print_mutex = threads.Mutex(print_mutex_id)
      print_mutex:lock()
      print('second_job', __threadid)
      print_mutex:unlock()
      print_mutex:free()
      return 'second job return message', __threadid
   end
   local run_id = block:run(second_job)
   print('Got run id: '..run_id)

   print('Synchronize the threads')
   block:synchronize()
   print('Getting execution results for first job')
   local result, status = block:getResult(1)
   for index, value in ipairs(result) do
      print(status[index], unpack(value))
   end
   print('Getting execution results for second job')
   local result, status = block:getResult(2)
   for index, value in ipairs(result) do
      print(status[index], unpack(value))
   end
   
   print('Terminating the threads')
   local result, status = block:terminate()
end

function joe:producerConsumerTest()
   print('Creating a producer block of 2 threads')
   local producers = Block(2)
   print('Creating a consumer block of 3 threads')
   local consumers = Block(3)
   print('Creating a vector as a producer-consumer queue')
   local queue = Vector(4)
   print('Creating an atomic as a print atomic guard')
   local atomic = Atomic()

   print('Adding the queue and atomic to procuder block')
   producers:add(queue, atomic)
   print('Adding the queue and atomic to consumer block')
   consumers:add(queue, atomic)

   local producer_job = function (queue, atomic)
      for i = 1, 6 do
         local value = __threadid * 1000 + i
         local status = queue:pushBack(value)
         atomic:write(function() print('produce', __threadid, i, value) end)
      end
   end

   local consumer_job = function (queue, atomic)
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      for i = 1, 4 do
         local value, status = queue:popFront()
         atomic:write(function() print('consume', __threadid, i, value) end)
         ffi.C.sleep(1)
      end
   end

   print('Starting prodecuer jobs')
   producers:run(producer_job)
   print('Starting consumer jobs')
   consumers:run(consumer_job)

   producers:terminate()
   consumers:terminate()
   print('Producers and consumers terminated')
end

joe.main()
return joe

