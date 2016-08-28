--[[
Unittest for Plural
Copyright 2016 Xiang Zhang
--]]

local Plural = require('tunnel.plural')

local Block = require('tunnel.block')
local Counter = require('tunnel.counter')
local Printer = require('tunnel.printer')
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
end

function joe:init()
   local printer = Printer()
   local vectors = Plural(3, Vector, 3)
   printer('Initialized vectors', #vectors)
   self.printer = printer
   self.vectors = vectors
end

function joe:pluralTest()
   local ret = self.vectors:doAll(
      function (index, vector)
         vector:pushBack('do_all '..index)
         return true
      end)
   for i, v in ipairs(ret) do
      self.printer('ret', i, v)
   end

   local popback_counter = Counter()
   local popback_block = Block(#self.vectors)
   popback_block:add(popback_counter, self.printer, self.vectors)
   popback_block:run(self:popBackJob())

   local pushback_counter = Counter()
   local pushback_block = Block(#self.vectors)
   pushback_block:add(pushback_counter, self.printer, self.vectors)
   pushback_block:run(self:pushBackJob())

   local status, result = popback_block:synchronize()
   for i, v in ipairs(status) do
      if v == false then
         self.printer('Error in popback_block', i, unpack(result[i]))
      end
   end
   local status, result = pushback_block:synchronize()
   for i, v in ipairs(status) do
      if v == false then
         self.printer('Error in pushback_block', i, unpack(result[i]))
      end
   end
end

function joe:popBackJob()
   return function (counter, printer, vectors)
      local id = counter:increase()
      printer('popback', __threadid, 'id', id)
      for i = 1, 60 do
         local value = vectors[id]:popBack(value)
         printer('popback', __threadid, id, i, value)
      end
   end
end

function joe:pushBackJob()
   return function (counter, printer, vectors)
      local math = require('math')
      local os = require('os')
      local id = counter:increase()
      printer('pushback', __threadid, 'id', id)
      math.randomseed(10000 + id * 1000 + os.time())
      for i = 1, 60 do
         local value = math.random(100)
         vectors[id]:pushBack(value)
         printer('pushback', __threadid, id, i, value)
      end
   end
end

joe.main()
return joe
