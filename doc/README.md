<a name="tunnel.doc"></a>
# Tunnel #
Tunnel is a data driven framework for distributed computing in Torch7. It consists of the following classes

* [`tunnel.Block`](#tunnel.block): a thread manager. In tunnel, a block is a group of threads that execute the same function.
* [`tunnel.Share`](#tunnel.share): a shared object wrapper. It can be used to wrap a data object to ensure shared serialization when transferring between threads.
* [`tunnel.Atomic`](#tunnel.atomic): an atomic object wrapper. It can be used to wrap a data object using the [reader-writer lock model](https://en.wikipedia.org/wiki/Readers%E2%80%93writers_problem), with both synchronous and asynchronous interface.
* [`tunnel.Printer`](#tunnel.printer): an atomic printer to standard output.
* [`tunnel.Vector`](#tunnel.vector): an synchronized vector data structure that can be used as an array, a queue, or a stack. It has both synchronous and asynchronous interface.
* [`tunnel.Hash`](#tunnel.hash): a synchronized hash table. It has both synchronous and asynchronous interface.
* [`tunnel.Serializer`](#tunnel.serializer): shared-serialization class. Do not use it unless you know what you are doing.

All of these classes will be available if you execute `require('tunnel')` in your program.

<a name="tunnel.block"></a>
## `tunnel.Block` ##

`tunnel.Block` is a thread manager. In `tunnel`, a block is a group of threads that execute the same function. The constructor can be used as

```lua
block = tunnel.Block(size, callback)
```

in which `size` is the number of threads for the threads, and `callback` is a function that is executed when these threads are initialized. The purpose of `callback` is to `require` some packages before starting executing the threads, since for some packages transferring data between threads is not possible unless you require them beforehand.

One such example is the `nn` package

```lua
init_job = function ()
   require('nn')
end
block = tunnel.Block(3, init_job)
```

Then, you will be able to transfer a `nn` module to the newly initialized thread using [`block:add`](#tunnel.block.add).

<a name="tunnel.block.add"></a>
### `block:add(data_1, data_2, ...)` ###

Link the thread block with the data objects in the argument. These data objects can be anything that is serializable by Torch. They will be passed as arguments to the callback function for each thread, when you execute `block:run(callback)`.

<a name="tunnel.block.run"></a>
### `run_id = block:run(callback)` ###

Send the `callback` function to each thread and execute it. The `callback` function should accept the data structures in the order when `block:add(data_1, data_2, ...)` was executed. You can send multiple callbacks to each thread by calling `block:run(callback)` multiple times and they will be executed in order inside each thread.

`run_id = block:run(callback)` immediately returns when it sends the callback to the threads. The return value is an id for the current callback that you can use in [`block:getResult()`](#tunnel.block.getresult) to obtain the execution results and status later. The id is simply a counting number of how many callbacks the block has received so far.

For example, the following code

```lua
first_job = function(printer, tensor)
   printer('first job', __threadid, tensor[1])
end
second_job = function(printer, tensor)
   printer('second job', __threadid, tensor[1])
end

tensor = torch.rand(1)
printer = tunnel.Printer()
block = tunnel.Block(2)
block:add(printer, tensor)
block:run(first_job)
block:run(second_job)
```

has one possible output as

```
first job       1       0.73844683496282
first job       2       0.73844683496282
second job      1       0.73844683496282
second job      2       0.73844683496282
```

The `printer` object is of type [`tunnel.Printer`](#tunnel.printer), which can make sure prints to standard output are synchronized.

<a name="tunnel.block.synchronize"></a>
### `result, status = block:synchronize()` ###

You can call `result, status = block:synchronize()` to wait for all threads in the block to complete all the submitted callbacks for running. `result` and `status` will be two [`tunnel.Vector`](#tunnel.vector) objects that contains the result and status of the last callback executed.

When `status[i] == true`, `result[i]` contains the returned results from thread `i` packed in a table. When `status[i] == false`, the callback in thread `i` has caught an error and the error message is packed in a table in `result[i]`.

For example

```lua
first_job = function()
   return __threadid, __threadid * 10
end
second_job = function()
   return __threadid, __threadid * 100
end
third_job = function()
   error('Error from thread '..tostring(__threadid))
   return __threadid, __threadid * 1000
end

block = tunnel.Block(2)
block:run(first_job)
result, status = block:synchronize()
print('Result for first job')
for i, v in ipairs(status) do
   print(i, v, unpack(result[i]))
end

block:run(second_job)
block:run(third_job)
result, status = block:synchronize()
print('Result for third job')
for i, v in ipairs(status) do
   print(i, v, unpack(result[i]))
end
```

The output could be

```
Result for first job
1       true    1       10
2       true    2       20
Result for third job
1       false   temp.lua:15: Error from thread 1
2       false   temp.lua:15: Error from thread 2
```

<a name="tunnel.block.getresult"></a>
### `result, status = block:getResult(run_id)`

`result, status = block:getResult(run_id)` will return the results and status for the callback indicated by `run_id`. The `run_id` is a counting number returned when `block:run(callback)` was called.

If `result` or `status` is `nil`, it means that `run_id` does not correspond to any callback submitted using `block:run(callback)`.

If `status[i] == nil`, it means that the result for the `i`-th thread hasn't returned yet. It is safe to check `status[i]` since it is a [`tunnel.Vector`](#tunnel.vector) object with read and write protection.

If `status[i] == true`, it means that the callback for thread `i` successfully completed, and the returned results from `callback` is packed as a table in `result[i]`.

If `status[i] == false`, it means that an error was caught while executing the corresponding callback, and the error message is packed in a table in `result[i]`. In this case, the thread continues to execute the next callback submitted through `block:run(callback)`.

```lua
first_job = function()
   local ffi = require('ffi')
   ffi.cdef('unsigned int sleep(unsigned int seconds);')
   ffi.C.sleep(1)
   return __threadid, __threadid * 10
end
second_job = function()
   return __threadid, __threadid * 100
end

block = tunnel.Block(2)
first_id = block:run(first_job)
second_id = block:run(second_job)

result, status = block:getResult(first_id)
for i, v in ipairs(status) do
   if v == nil then
      print('thread '..i..' hasn\'t finished first job yet')
   end
end

result, status = block:synchronize()
print('Result for second job')
for i, v in ipairs(status) do
   print(i, v, unpack(result[i]))
end

result, status = block:getResult(first_id)
print('Result for first job')
for i, v in ipairs(status) do
   print(i, v, unpack(result[i]))
end
```

The result is usually like this
```
thread 1 hasn't finished first job yet
thread 2 hasn't finished first job yet
Result for second job
1       true    1       100
2       true    2       200
Result for first job
1       true    1       10
2       true    2       20
```

<a name="tunnel.block.terminate"></a>
### `result, status = block:terminate()` ###

Terminate all the threads and release all its resources. The result and status of the last job ran will be returned. If you call `block:run(callback)` after this, an error will pop indicating the threads system is not running for the block.

This function is automatically called by the garbage collector when `block` cannot be reached, and when the garbage collector decides to run. It should not be called manually.

```lua
first_job = function()
   return __threadid, __threadid * 10
end
second_job = function()
   return __threadid, __threadid * 100
end

block = tunnel.Block(2)
block:run(first_job)

result, status = block:terminate()
print('Result for first job')
for i, v in ipairs(status) do
   print(i, v, unpack(result[i]))
end

-- ERROR!
block:run(second_job)
```

The result is like this

```
$ th temp.lua
Result for first job
1       true    1       10
2       true    2       20
luajit: threads/threads.lua:135: thread system is not running
$
```

<a name="tunnel.share"></a>
## `tunnel.Share` ##

`tunnel.Share` is a class that enforces shared serialization for the data it wraps. It utilizes [`tunnel.Serializer`](#tunnel.serializer) for the job, and right now the following data can be share-serialized

* `torch.*Storage`
* `torch.*Tensor`
* `tds.Hash` or `tds.hash`
* `tds.Vec` or `tds.vec`
*  The above objects inside plain lua tables (including nested tables), such as `nn` modules.

Share serialization means that when serialize the data, only the underlying data pointer is stored. This way, when the it is deserialized, an object pointing to the same data in memory is restored. Since transferring data between threads is a serialize-deserialize process, this allows different threads to access the same data in memory.

By default, the [`threads`](https://github.com/torch/threads) library uses copy serialization instead of share serialization, unless it is set by calling `threads.serialization('threads.sharedserialization')`. But `tunnel.Share` enforces share serialization regardless of the default serialization method in `threads` library.

You can construct a shared object using
```lua
share = tunnel.Share(data)
```

then `data` can be accessed by `share.data`. Note that `tunnel.Share` does not provide any atomic protection to `data`. For that, use [`tunnel.Atomic`](#tunnel.atomic).

```lua
job = function(printer, copied, shared)
   printer('thread', __threadid, copied[1], shared[1])
   copied[1] = __threadid
   shared.data[1] = __threadid
   printer('thread', __threadid, copied[1], shared[1])
end

printer = tunnel.Printer()
copied = torch.rand(1)
shared = tunnel.Share(torch.rand(1))
printer('main', copied[1], shared.data[1])

block = tunnel.Block(2)
block:add(printer, copied, shared)
block:run(job)
block:synchronize()

printer('main', copied[1], shared.data[1])
```

One possible result looks like the following. Note that the data in `copied` is not changed in the main thread.

```
main    0.43298867880367        0.963158614235
thread  1       0.43298867880367        0.963158614235
thread  1       1       1
thread  2       0.43298867880367        1
thread  2       2       2
main    0.43298867880367        2
```

<a name="tunnel.share.access"></a>
### `result = share:access(callback)` ###

This function uses `callback` to access data, and return the result of `callback`. Here is an equivalent implementation of the example above, but using `share:access(callback)` instead of `share.data`.

```lua
job = function(printer, copied, shared)
   printer('thread', __threadid, copied[1], shared:access(
              function(data) return data[1] end))
   copied[1] = __threadid
   printer('thread', __threadid, copied[1], shared:access(
              function(data)
                 data[1] = __threadid
                 return data[1]
              end))
end

printer = tunnel.Printer()
copied = torch.rand(1)
shared = tunnel.Share(torch.rand(1))
printer('main', copied[1], shared.data[1])

block = tunnel.Block(2)
block:add(printer, copied, shared)
block:run(job)
block:synchronize()

printer('main', copied[1], shared.data[1])
```

<a name="tunnel.atomic"></a>
## `tunnel.Atomic` ##

`tunnel.Atomic` is a wrapper class for data objects. Similar to [`tunnel.Share`](#tunnel.share), it enforces share serialization as well. It also provides an atomic [reader-writer lock mechanism](https://en.wikipedia.org/wiki/Readers%E2%80%93writers_problem) which can be used for synchronization purposes, with both synchronous and asynchronous interfaces.

```lua
atomic = tunnel.Atomic(data)
```

`atomic` has a member called `atomic.data` that can be used to access `data`, but it is not protected. To get protected atomic behavior, use the read and write functions of `atomic`. 

```lua
job = function(printer, atomic)
   local ffi = require('ffi')
   local math = require('math')
   ffi.cdef('unsigned int sleep(unsigned int seconds);')
   math.randomseed(__threadid * 1000)
   for i = 1, 5 do
      local choice = math.random(4)
      local value = __threadid * 1000 + i
      local status = false
      if choice == 1 then
         status = atomic:write(
            function (data)
               data[1] = value
               ffi.C.sleep(1)
               return true
            end)
         printer('sync_write', __threadid, value, status == true)
      elseif choice == 2 then
         value, status = atomic:read(
            function (data)
               ffi.C.sleep(1)
               return data[1], true
            end)
         printer('sync_read', __threadid, value or 'nil', status == true)
      elseif choice == 3 then
         status = atomic:writeAsync(
            function (data)
               ffi.C.sleep(1)
               data[1] = value
               return true
            end)
         printer('async_write', __threadid, value, status == true)
      else
         value, status = atomic:readAsync(
            function (data)
               ffi.C.sleep(1)
               return data[1], true
            end)
         printer('async_read', __threadid, value or 'nil', status == true)
      end
   end
end

printer = tunnel.Printer()
atomic = tunnel.Atomic(torch.zeros(1))
block = tunnel.Block(3)
block:add(printer, atomic)
block:run(job)
block:synchronize()
printer('main', atomic:read(function(data) return data[1] end))
```

The program above initializes 3 threads and each randomly choose to do read or write for 5 iterations, using either synchronous or asynchronous interface. Below is one possible output. The four reading and writing functions are documented afterwards.

```
async_read      3       nil     false
sync_read       1       0       true
sync_write      2       2001    true
async_read      2       nil     false
async_write     2       2003    false
async_write     2       2004    false
sync_write      3       3002    true
async_write     3       3003    false
sync_read       1       3002    true
sync_read       2       3002    true
async_read      1       nil     false
async_write     1       1004    false
async_read      1       nil     false
sync_write      3       3004    true
async_write     3       3005    true
main    3005
```

<a name="tunnel.atomic.write"></a>
### `result = atomic:write(callback)` ###

A synchronous write operation in which `callback` is called by passing `atomic.data` as its argument. The result after executing `callback(atomic.data)` is returned.

`atomic:write` acquires exclusive access to the data when executing `callback`. If there are other writers or readers accessing data, the synchronous writer waits until all these jobs are finished before acquiring the exclusive access and executing `callback`. Therefore, a synchronous write operation will always be successful.

<a name="tunnel.atomic.writeasync"></a>
### `result = atomic:writeAsync(callback)` ###

An asynchronous write operation in which `callback` is called by passing `atomic.data` as its argument. If the data access can be acquired successfully, the result after executing `callback(atomic.data)` is returned.

`atomic:writeAsync` attempts to acquire exclusive access to the data when executing `callback`. If there are other writers or readers accessing data, the asynchronous writer returns immediately without executing `callback`. Therefore, an asynchronous write operation may fail.

<a name="tunnel.atomic.read"></a>
### `result = atomic:read(callback)` ###

A synchronous read operation in which `callback` is called by passing `atomic.data` as its argument. The result after executing `callback(atomic.data)` is returned.

`atomic:read()` allows multiple readers (synchronous or asynchronous) to access data, so one must ensure that `callback` should do read-only operations. If some write operation is executing when it attempts to access data, the synchronous reader waits until the writer is finished before executing `callback`. Therefore, a synchronous read operation will always be successful.

<a name="tunnel.atomic.readasync"></a>
### `result = atomic:readAsync(callback)` ###

An asynchronous read operation in which `callback` is called by passing `atomic.data` as its argument. if the data access can be acquired successfully, the result after executing `callback(atomic.data)` is returned.

`atomic:readAsync()` allows multiple readers (synchronous or asynchronous) to access data, so one must ensure that `callback` should do read-only operations. If some write operation is executing when it attempts to access data, the asynchronous reader returns immediately without executing `callback`. Therefore, an asynchronous read operation may fail.

<a name="tunnel.atomic.summary"></a>
### Summary ###

The following table summarizes the compatibility and behavior of these four access functions.

|              | Other Readers  | Other Writers  | Incompatibility Behavior |
|--------------|----------------|----------------|--------------------------|
| `write`      |  Incompatible  |  Incompatible  | Wait for access          |
| `writeAsync` |  Incompatible  |  Incompatible  | Return immediately       |
| `read`       |   Compatible   |  Incompatible  | Wait for access          |
| `readAsync`  |   Compatible   |  Incompatible  | Return immediately       |

<a name="tunnel.printer"></a>
## `tunnel.Printer` ##

`tunnel.Printer` is a class that wraps Lua `print` and `io.write` functions inside an atomic lock. You can create a printer by calling

```lua
printer = tunnel.Printer()
```

When print to standard output, `printer` will ensure that only one thread is granted access. If multiple threads are accessing `printer` at the same time, they will queue up and print one at a time.

```lua
job = function(printer)
   local ffi = require('ffi')
   local io = require('io')
   ffi.cdef('unsigned int sleep(unsigned int seconds);')
   printer:write(__threadid, '\t', 'Print with synchronization\n')
   ffi.C.sleep(1)
   io.write(__threadid, '\t', 'Print without synchronization\n')
end

printer = tunnel.Printer()
block = tunnel.Block(3)
block:add(printer)
block:run(job)
```

Here is one possible output.

```
1       Print with synchronization
2       Print with synchronization
3       Print with synchronization
1       Print without syn3       Print withchronization
2       Prinout synchronization
t without synchronization
```

<a name="tunnel.printer.print"></a>
### `status = printer:print(...)` ###

A synchronous equivalent of calling `print(...)`. If `status == true`, the print is successful.

If there are other printing operations, the synchronous print will wait for them to end. Therefore, the print will always be attempted.

<a name="tunnel.printer.printAsync"></a>
### `status = printer:printAsync(...)` ###

An asynchronous equivalent of calling `print(...)`. If `status == true`, the print is successful.

If there are other printing operations, the asynchronous print will return immediately and `status` will be `nil` in this case. Therefore, the print may not be attempted.

<a name="tunnel.printer.write"></a>
### `status = printer:write(...)` ###

A synchronous equivalent of calling `io.write(...)`. If `status == true`, the write is successful.

If there are other printing operations, the synchronous write will wait for them to end. Therefore, the write will always be attempted.

<a name="tunnel.printer.writeAsync"></a>
### `status = printer:writeAsync(...)` ###

An asynchronous equivalent of calling `io.write(...)`. If `status == true`, the write is successful.

If there are other printing operations, the asynchronous write will return immediately and `status` will be `nil` in this case. Therefore, the write may not be attempted.

<a name="tunnel.printer.access"></a>
### `result = printer:access(callback)` ###

A synchronous access. It executes `callback()` and return its result. While `callback()` is executing, no printing is permitted. This is useful if you want to do some batch printing, such as iterating over synchronized data structures.

If there are other printing operations, the synchronous access will wait for them to end. Therefore, the access will always be attempted.

<a name="tunnel.printer.access"></a>
### `result = printer:accessAsync(callback)` ###

An asynchronous access. It executes `callback()` and return its result. While `callback()` is executing, no printing is permitted. This is useful if you want to do some batch printing, such as iterating over synchronized data structures.

If there are other printing operations, the asynchronous access will return immediately without executing `callback`. Therefore, the access may not be attempted.

<a name="tunnel.printer.call"></a>
### `printer:__call(...)` ###

The call operator is overloaded such that calling

```lua
printer(...)
```

is the same as

```lua
printer:print(...)
```

<a name="tunnel.vector"></a>
## `tunnel.Vector` ##

`tunnel.Vector` is a class that can represent an array, a queue or a stack. It has synchronous methods that wait for space or data availability, and asynchronous methods that returns immediately if no space or data available. `nil` values can be stored in a vector in the same way as any other kind of values. This means that setting a value at some index to `nil` does not remove it, different from usual Lua tables.

The underlying storage is based on the `tds.Vec` class, with the additional mechanism of enforced share-serialization on values (not on indices since they are just numbers). Such enforcement has the following two advantages

1. The type of data that can be stored in a vector is greatly expanded. For example, `tunnel.Vector` can store boolean values and Torch tensors, while `tds.Vec()` will give errors if used directly.
2. The values can be transferred between threads with maximum compatibility between different types. Since it uses shared-serialization, the memory overhead is minimal.

In short, any value you store in `tunnel.Vector` is automatically shared across different threads as if they were wrapped in `tunnel.Share`.

To create a vector, simply call

```
vector = tunnel.Vector(size_hint)
```

The `size_hint` is a parameter used by `push*` to determine whether to add values to the vector any more. It defaults to `math.huge`.

The following is an example of using `tunnel.Vector` to solve producer-consumer problem by using it as a product queue.

```lua
produce = function (vector, printer)
   for i = 1, 6 do
      local product = __threadid * 1000 + i
      vector:pushBack(product)
      printer('produce', __threadid, i, product)
   end
end

consume = function (vector, printer)
   local ffi = require('ffi')
   ffi.cdef('unsigned int sleep(unsigned int seconds);')
   for i = 1, 4 do
      local product = vector:popFront()
      printer('consume', __threadid, i, product)
      -- Pretend it takes 1 second to consume a product
      ffi.C.sleep(1)
   end
end


local vector = tunnel.Vector(4)
local printer = tunnel.Printer()
local producer_block = tunnel.Block(2)
local consumer_block = tunnel.Block(3)
producer_block:add(vector, printer)
consumer_block:add(vector, printer)
producer_block:run(produce)
consumer_block:run(consume)
```

The following is one possible output. Note that the program can end properly because the total number of products being produced is 12, and the same number of products will be consumed.

```
produce 1       1       1001
produce 1       2       1002
produce 1       3       1003
produce 1       4       1004
consume 1       1       1001
produce 1       5       1005
consume 2       1       1002
produce 2       1       2001
consume 3       1       1003
produce 1       6       1006
consume 1       2       1004
produce 2       2       2002
consume 2       2       1005
produce 2       3       2003
consume 3       2       2001
produce 2       4       2004
consume 1       3       1006
produce 2       5       2005
produce 2       6       2006
consume 2       3       2002
consume 3       3       2003
consume 1       4       2004
consume 2       4       2005
consume 3       4       2006
```

<a name="tunnel.vector.insert"></a>
### `status = vector:insert([index,] value)` ###

This method is synchronous insertion, a modification operation. Insert the `value` at `index`, and shift all the original values starting from `index` to their next locations. If `index` is not provided, insert to the end of the vector. Insertion can only be successful when `index <= vector:size() + 1`, in which case `status` will be `true`. Otherwise `status` will be `nil`.

If there are other operations accessing the vector, the synchronous insertion will wait for exclusive access. Therefore, the insertion will always be attempted.

<a name="tunnel.vector.insertasync"></a>
### `status = vector:insertAsync([index,] value)` ###

This method is asynchronous insertion, a modification operation. Insert the `value` at `index`, and shift all the original values starting from `index` to their next locations. If `index` is not provided, insert to the end of the vector. If `status == true`, then an insertion operation is attempted and successful. It can only be successful when `index <= vector:size() + 1`, in which case `status` will be `true`. Otherwise `status` will be `nil`.

If there are other operations accessing the vector, the asynchronous insertion will return immediately, in which case `status` is also `nil`. Therefore, the insertion may not be attempted.

<a name="tunnel.vector.remove"></a>
### `value, status = vector:remove([index])` ###

This method is synchronous removal, a modification operation. It removes the value at `index`, and shift all the values starting from `index + 1` to their previous locations. If `index` is not provided, remove the value at the end of the vector. Removal can only be successful when `index <= vector:size()`, in which case `status` is `true` and `value` contains the removed value. Otherwise `status` will be `nil`.

If there are are other operations accessing the vector, the synchronous removal will wait for exclusive access. Therefore, the removal will always be attempted.

Note that it is possible for `value` to be `nil` when `status` is `true` since storing `nil` as value is allowed.

<a name="tunnel.vector.removeasync"></a>
### `value, status = vector:removeAsync([index])` ###

This method is asynchronous removal, a modification operation. It removes the value at `index`, and shift all the values starting from `index + 1` to their previous locations. If `index` is not provided, remove the value at the end of the vector. If `status == true`, then a removal operation is attempted and successful. It can only be successful when `index <= vector:size()`, in which case `status` is `true` and `value` contains the removed value. Otherwise `status` will be `nil`.

If there are are other operations accessing the vector, the asynchronous removal will return immediately, in which case `status` is also `nil`. Therefore, the removal may not be attempted.

Note that it is possible for `value` to be `nil` when `status` is `true` since storing `nil` as value is allowed.

<a name="tunnel.vector.pushfront"></a>
### `status = vector:pushFront(value)` ###

This method is synchronous front push, a modification operation. It inserts the value at the first location of the vector, and all the originals values will be moved to their next location. If `status == true`, then the push operation is successful.

If `vector:size() >= vector.size_hint` (a value set when calling the constructor), the synchronous front push will wait until the `vector:size() < vector.size_hint` and then attempt to push. If there are other operations, the synchronous front will wait for exclusive access. Therefore, the push will always be attempted.

Note that because there can be simutaneous attempts to push when `vector:size() < vector.size_hint` is satisfied, there is no guarantee that after pushing `vector:size()` is smaller than or equal to `vector.size_hint`. This is why the parameter is called a size "hint".

<a name="tunnel.vector.pushfrontasync"></a>
### `status = vector:pushFrontAsync(value)` ###

This method is asynchronous front push, a modification operation. It inserts the value at the first location of the vector, and all the originals values will be moved to their next location. If `status == true`, then the push operation is attempted and successful.

If `vector:size() >= vector.size_hint` (a value set when calling the constructor) or if there are other operations, the asynchronous push returns immediately and `status` will be `nil` in this case. Therefore, the push may not be attempted.

Note that because there can be simutaneous attempts to push when `vector:size() < vector.size_hint` is satisfied, there is no guarantee that after pushing `vector:size()` is smaller than or equal to `vector.size_hint`. This is why the parameter is called a size "hint".

<a name="tunnel.vector.popfront"></a>
### `value, status = vector:popFront()` ###

This method is synchronous front pop, a modification operation. It pops the value at the first location of the vector and shift all values starting from index 2 to their previous locations. If `status == true`, the pop operation is successful and `value` stores the popped value.

If `vector:size() == 0`, the synchronouos pop will wait until a value is available in the vector and then attempt to pop. If there are other operations, the synchronous pop will wait for exclusive access. Therefore, the pop will always be attempted.

Note that it is possible for `value` to be `nil` when `status` is `true` since storing `nil` as value is allowed.

<a name="tunnel.vector.popfrontasync"></a>
### `value, status = vector:popFrontAsync()` ###

This method is asynchronous front pop, a modification operation. It pops the value at the first location of the vector and shift all values starting from index 2 to their previous locations. If `status == true`, the pop operation is attempted and successful, and `value` stores the popped value.

If `vector:size() == 0` or if there are other operations, the synchronous pop will return immediately and `status` will be `nil` in this case. Therefore, the pop may not be attempted.

Note that it is possible for `value` to be `nil` when `status` is `true` since storing `nil` as value is allowed.

<a name="tunnel.vector.pushback"></a>
### `status = vector:pushBack(value)` ###

This method is synchronous back push, a modification operation. It inserts the value at the end of the vector. If `status == true`, then the push operation is successful.

If `vector:size() >= vector.size_hint` (a value set when calling the constructor), the synchronous front push will wait until the `vector:size() < vector.size_hint` and then attempt to push. If there are other operations, the synchronous front will wait for exclusive access. Therefore, the push will always be attempted.

Note that because there can be simutaneous attempts to push when `vector:size() < vector.size_hint` is satisfied, there is no guarantee that after pushing `vector:size()` is smaller than or equal to `vector.size_hint`. This is why the parameter is called a size "hint".

<a name="tunnel.vector.pushbackasync"></a>
### `status = vector:pushBackAsync(value)` ###

This method is asynchronous back push, a modification operation. It inserts the value at the end of the vector. If `status == true`, then the push operation is attempted and successful.

If `vector:size() >= vector.size_hint` (a value set when calling the constructor) or if there are other operations, the asynchronous push returns immediately and `status` will be `nil` in this case. Therefore, the push may not be attempted.

Note that because there can be simutaneous attempts to push when `vector:size() < vector.size_hint` is satisfied, there is no guarantee that after pushing `vector:size()` is smaller than or equal to `vector.size_hint`. This is why the parameter is called a size "hint".

<a name="tunnel.vector.popback"></a>
### `value, status = vector:popBack()` ###

This method is synchronous back pop, a modification operation. It pops the value at the end of the vector. If `status == true`, the pop operation is successful and `value` stores the popped value.

If `vector:size() == 0`, the synchronouos pop will wait until a value is available in the vector and then attempt to pop. If there are other operations, the synchronous pop will wait for exclusive access. Therefore, the pop will always be attempted.

Note that it is possible for `value` to be `nil` when `status` is `true` since storing `nil` as value is allowed.

<a name="tunnel.vector.popbackasync"></a>
### `value, status = vector:popBackAsync()` ###

This method is asynchronous back pop, a modification operation. It pops the value at the end of the vector. If `status == true`, the pop operation is attempted and successful, and `value` stores the popped value.

If `vector:size() == 0` or if there are other operations, the synchronous pop will return immediately and `status` will be `nil` in this case. Therefore, the pop may not be attempted.

Note that it is possible for `value` to be `nil` when `status` is `true` since storing `nil` as value is allowed.

<a name="tunnel.vector.get"></a>
### `value, status = vector:get(index)` or `value = vector[index]` ###

This method is synchronous getter, a read-only operation. It gets the value at `index` and return it. If `status == true`, the get operation is successful.

If there are other modification operations, the synchronous getter will wait for them to end. Therefore, the get will always be attempted.

<a name="tunnel.vector.getasync"></a>
### `value, status = vector:getAsync(index)` ###

This method is asynchronous getter, a read-only operation. It gets the value at `index` and return it. If `status == true`, the get operation is attempted and successful.

If there are other modification operations, the asynchronous getter will return immediately and `status` will be `nil` in this case. Therefore, the get may not be attempted.

<a name="tunnel.vector.set"></a>
### `status = vector:set(index, value)` or `vector[index] = value` ###

This method is synchronous setter, a modification operation. It sets the value at `index` to be `value`, resizing the vector to have size at least `index` if necessary by filling it with `nil` values. Note that when `value == nil`, it means to set the value at `index` to nil rather than to delete the value. If `status == true`, the set operation is successful.

If there are other operations, the synchronous setter will wait for exclusive access. Therefore, the set will always be attempted.

<a name="tunnel.vector.setasync"></a>
### `status = vector:setAsync(index, value)` ###

This method is asynchronous setter, a modification operation. It sets the value at `index` to be `value`, resizing the vector to have size at least `index` if necessary by filling it with `nil` values. Note that when `value == nil`, it means to set the value at `index` to nil rather than to delete the value. If `status == true`, the set operation is attempted and successful.

If there are other operations, the synchronous setter will return immediately and `status` will be `nil` in this case. Therefore, the set may not be attempted.

<a name="tunnel.vector.read"></a>
### `result = vector:read(index, callback)` ###

This method is synchronous read, a read-only operation. It gets the value at `index` and calls `callback(value)`. The result of `callback` is returned. While `callback` is executing, no modification operation is permitted so as to ensure that the value is not modified during `callback`. You should not make modification to `value` in `callback`.

If there are other modification operations, the synchronous read will wait for them to end. Therefore, the read will always be attempted.

<a name="tunnel.vector.readAsync"></a>
### `result = vector:readAsync(index, callback)` ###

This method is asynchronous read, a read-only operation. It gets the value at `index` and calls `callback(value)`. The result of `callback` is returned. While `callback` is executing, no modification operation is permitted so as to ensure that the value is not modified during `callback`. You should not make modifications to `value` in `callback`.

If there are other modification operations, the asynchronous read will return immediately without executing `callback`. Therefore, the read may not be attempted.

<a name="tunnel.vector.write"></a>
### `status, value = vector:write(index, callback)` ###

This method is synchronous write, a modification operation. It gets the value at `index` and calls `callback(value)`, then put `callback`'s returned value at `index` of the vector. If `status == true`, the write operation is successful. While `callback` is executing, neither modification nor read-only operation is permitted so as to ensure that the value can be modified during `callback`.

If there are other operations, the synchronous write will wait for exclusive access. Therefore, the write will always be attempted.

<a name="tunnel.vector.writeasync"></a>
### `status, value = vector:writeAsync(index, callback)` ###

This method is asynchronous write, a modification operation. It gets the value at `index` and calls `callback(value)`, then put `callback`'s returned value at `index` of the vector. If `status == true`, the write operation is attempted and successful. While `callback` is executing, neither modification nor read-only operation is permitted so as to ensure that the value can be modified during `callback`.

If there are other operations, the asynchronous write will return immediately without executing `callback` and `status` will be `nil` in this case. Therefore, the write may not be attempted.

<a name="tunnel.vector.size"></a>
### `size = vector:size()` or `size = #vector` ###

This method is synchronous size property, a read-only operation. It gets the size of the vector. If `size ~= nil`, the size property function is successful.

If there are other modification operations, the synchronous size property function will wait for them to end. Therefore, the size property function will always be attempted.

<a name="tunnel.vector.sizeasync"></a>
### `size = vector:sizeAsync()` ###

This method is asynchronous size property, a read-only operation. It gets the size of the vector. If `size ~= nil`, the size property function is attempted and successful.

If there are other modification operations, the asynchronous size property function will return immediately. Therefore, the size property function may not be attempted.

<a name="tunnel.vector.sort"></a>
### `status = vector:sort(compare)` ###

This method is synchronous sort, a modification operation. It sorts the values according to the `compare` callback. The callback should accept two values, and `compare(a, b)` should return `true` if `a` should precede `b` in the order. If `status == true`, the sort is successful.

If there are other operations, the synchronous sort will wait for exclusive access. Therefore, the sort operation will always be attempted.

<a name="tunnel.vector.sortasync"></a>
### `status = vector:sortAsync(compare)` ###

This method is asynchronous sort, a modification operation. It sorts the values according to the `compare` callback. The callback should accept two values, and `compare(a, b)` should return `true` if `a` should precede `b` in the order. If `status == true`, the sort is attempted and successful.

If there are other operations, the asynchronous sort will return immediately. Therefore, the sort operation may not be attempted.

<a name="tunnel.vector.iterator"></a>
### `iterator, status = vector:iterator()` or `iterator = ipairs(vector)` or `iterator = pairs(vector)` ###

This method is synchronous iterator, a read-only operation. It gets a snapshot clone of the vector and put its indices and values for iteration. If `status == true`, the iterator obtain is successful.

If there are other modification operations, the synchronous iterator will wait for them to end. Therefore, the iterator obtain will always be attempted.

<a name="tunnel.vector.iteratorasync"></a>
### `iterator, status = vector:iteratorAsync()` ###

This method is asynchronous iterator, a read-only operation. It gets a snapshot clone of the vector and put its indices and values for iteration. If `status == true`, the iterator obtain is attempted and successful.

If there are other modification operations, the asynchronous iterator will return immediately. Therefore, the iterator obtain may not be attempted.

<a name="tunnel.vector.tostring"></a>
### `str = vector:toString()` or `str = tostring(vector)` ###

This method is synchronous string conversion, a read-only operation. It returns the string representation of the underlying `tds.Vec`. If `str ~= nil`, the string conversion is successful.

If there are other modification operations, the synchronous string conversion will wait for them to end. Therefore the string conversion will always be attempted.

Note that becuase the values stored in `vector` are serialized, the string conversion result may not be readable.

<a name="tunnel.vector.tostringasync"></a>
### `str = vector:toStringAsync()` ###

This method is asynchronous string conversion, a read-only operation. It returns the string representation of the underlying `tds.Vec`. If `str ~= nil`, the string conversion is attempted and successful.

If there are other modification operations, the asynchronous string conversion will return immediately. Therefore the string conversion may not be attempted.

Note that becuase the values stored in `vector` are serialized, the string conversion result may not be readable.

<a name="tunnel.vector.summary"></a>
### Summary ###

The following is a table summarizing all the functions in `tunnel.Vector` and their compatibility. Note that all read-only operations are compatible with each other, which means that multiple threads can do multiple read-only operations at the same time.

|                  |     Type     | Other Read-only | Other Modification | Incompatibility Behavior |
|------------------|:------------:|:---------------:|:------------------:|--------------------------|
| `insert`         | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `insertAsync`    | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `remove`         | Modification |   Incomptable   |    Incompatible    | Wait for access          |
| `removeAsync`    | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `pushFront`      | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `pushFrontAsync` | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `popFront`       | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `popFrontAsync`  | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `pushBack`       | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `pushBackAsync`  | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `popBack`        | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `popBackAsync`   | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `get`            | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `getAsync`       | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `set`            | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `setAsync`       | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `read`           | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `readAsync`      | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `write`          | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `writeAsync`     | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `size`           | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `sizeAsync`      | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `sort`           | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `sortAsync`      | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `iterator`       | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `iteratorAsync`  | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `toString`       | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `toStringAsync`  | Read-only    |    Compatible   |    Incompatible    | Return immediately       |

<a name="tunnel.hash"></a>
## `tunnel.Hash` ##

`tunnel.Hash` is a class that can represent a hash table. This data structure has the same value serialization semantics as `tunnel.Vector`, that is, each value stored is as if wrapped inside a `tunnel.Share` for enforced share serialization. `tunnel.Hash` uses `tds.Hash` as the underlying data structure. It could be useful for storing shared state data across different threads or blocks. To create a hash table, simply call the constructor like below.

`nil` values are not permitted in hash, and setting a value at some key to be `nil` will delete the entry. This is the same as Lua tables.

```lua
hash = tunnel.Hash()
```

As an example, the following code use the hash table to store a counter for the progress of each thread.

```lua
job = function (state)
   for i = 1, 6 do
      state['thread_'..tostring(__threadid)] =
         (state['thread_'..tostring(__threadid)] or 0) + 1
   end
end

state = tunnel.Hash()
block = tunnel.Block(3)
block:add(state)
block:run(job)
result, status = block:synchronize()

for key, value in pairs(state) do
   if type(value) == 'number' then
      print(key, value)
   else
      print(key, value.data[1])
   end
end
```

Here is one possible output

```
thread_1        6
thread_3        6
thread_2        6
```

<a name="tunnel.hash.get"></a>
### `value, hash = hash:get(key)` or `value = hash[key]` ###

This method is synchronous getter, a read-only operation. It gets the value at `key` and return it. If `status == true`, the get operation is successful.

If there are other modification operations, the synchronous getter will wait for them to end. Therefore, the get will always be attempted.

<a name="tunnel.hash.getasync"></a>
### `value, status = hash:getAsync(key)` ###

This method is asynchronous getter, a read-only operation. It gets the value at `key` and return it. If `status == true`, the get operation is attempted and successful.

If there are other modification operations, the asynchronous getter will return immediately and `status` will be `nil` in this case. Therefore, the get may not be attempted.

<a name="tunnel.hash.set"></a>
### `status, old_value = hash:set(key, value)` or `hash[key] = value` ###

This method is synchronous setter, a modification operation. It sets the value at `key` to be `value`. If `value == nil`, the hash table entry is deleted. If `status == true`, the set operation is successful.

If there are other operations, the synchronous setter will wait for exclusive access. Therefore, the set will always be attempted.

> Warning: due to Lua metatable limitations, if the `__newindex` operator is used such as `hash[key] = value`, make sure `key` is not any data member or any function name of the `tunnel.Hash` data structure. The data members currently include `hash.hash`, `hash.serializer` and `hash.count`, but there is no guarantee that this will not change in the future.

<a name="tunnel.hash.setasync"></a>
### `status, old_value = hash:setAsync(key, value)` ###

This method is asynchronous setter, a modification operation. It sets the value at `key` to be `value`. If `value == nil`, the hash table entry is deleted. If `status == true`, the set operation is attempted and successful.

If there are other operations, the asynchronous setter return immediately and `status` will be `nil` in this case. Therefore, the set may not be attempted.

<a name="tunnel.hash.read"></a>
### `result = hash:read(key, callback)` ###

This method is synchronous read, a read-only operation. It gets the value at `key` and calls `callback(value)`. The result of `callback` is returned. While `callback` is executing, no modification operation is permitted so as to ensure that the value is not modified during `callback`. You should not make modification to `value` in `callback`.

If there are other modification operations, the synchronous read will wait for them to end. Therefore, the read will always be attempted.

<a name="tunnel.hash.readAsync"></a>
### `result = hash:readAsync(key, callback)` ###

This method is asynchronous read, a read-only operation. It gets the value at `key` and calls `callback(value)`. The result of `callback` is returned. While `callback` is executing, no modification operation is permitted so as to ensure that the value is not modified during `callback`. You should not make modifications to `value` in `callback`.

If there are other modification operations, the asynchronous read will return immediately without executing `callback`. Therefore, the read may not be attempted.

<a name="tunnel.hash.write"></a>
### `status, value = hash:write(key, callback)` ###

This method is synchronous write, a modification operation. It gets the value at `key` and calls `callback(value)`, then put `callback`'s returned value at `key` of the hash. If `status == true`, the write operation is successful. While `callback` is executing, neither modification nor read-only operation is permitted so as to ensure that the value can be modified during `callback`.

If there are other operations, the synchronous write will wait for exclusive access. Therefore, the write will always be attempted.

<a name="tunnel.hash.writeasync"></a>
### `status, value = hash:writeAsync(key, callback)` ###

This method is asynchronous write, a modification operation. It gets the value at `key` and calls `callback(value)`, then put `callback`'s returned value at `key` of the hash. If `status == true`, the write operation is attempted and successful. While `callback` is executing, neither modification nor read-only operation is permitted so as to ensure that the value can be modified during `callback`.

If there are other operations, the asynchronous write will return immediately without executing `callback` and `status` will be `nil` in this case. Therefore, the write may not be attempted.

<a name="tunnel.hash.size"></a>
### `size = hash:size()` ###

This method is synchronous size property, a read-only operation. It gets the size of the hash. If `size ~= nil`, the size property function is successful.

If there are other modification operations, the synchronous size property function will wait for them to end. Therefore, the size property function will always be attempted.

<a name="tunnel.hash.sizeasync"></a>
### `size = hash:sizeAsync()` ###

This method is asynchronous size property, a read-only operation. It gets the size of the hash. If `size ~= nil`, the size property function is attempted and successful.

If there are other modification operations, the asynchronous size property function will return immediately. Therefore, the size property function may not be attempted.

<a name="tunnel.hash.iterator"></a>
### `iterator, status = hash:iterator()` or `iterator = pairs(hash)` ###

This method is synchronous iterator, a read-only operation. It gets a snapshot clone of the hash and put its keys and values for iteration. If `status == true`, the iterator obtain is successful.

If there are other modification operations, the synchronous iterator will wait for them to end. Therefore, the iterator obtain will always be attempted.

<a name="tunnel.hash.iteratorasync"></a>
### `iterator, status = hash:iteratorAsync()` ###

This method is asynchronous iterator, a read-only operation. It gets a snapshot clone of the hash and put its keys and values for iteration. If `status == true`, the iterator obtain is attempted and successful.

If there are other modification operations, the asynchronous iterator will return immediately. Therefore, the iterator obtain may not be attempted.

<a name="tunnel.hash.tostring"></a>
### `str = hash:toString()` or `str = tostring(hash)` ###

This method is synchronous string conversion, a read-only operation. It returns the string representation of the underlying `tds.Hash`. If `str ~= nil`, the string conversion is successful.

If there are other modification operations, the synchronous string conversion will wait for them to end. Therefore the string conversion will always be attempted.

Note that becuase the values stored in `hash` are serialized, the string conversion result may not be readable.

<a name="tunnel.hash.tostringasync"></a>
### `str = hash:toStringAsync()` ###

This method is asynchronous string conversion, a read-only operation. It returns the string representation of the underlying `tds.Hash`. If `str ~= nil`, the string conversion is attempted and successful.

If there are other modification operations, the asynchronous string conversion will return immediately. Therefore the string conversion may not be attempted.

Note that because the values stored in `hash` are serialized, the string conversion result may not be readable.

<a name="tunnel.hash.summary"></a>
### Summary ###

The following is a table summarizing all the functions in `tunnel.Hash` and their compatibility. Note that all read-only operations are compatible with each other, which means that multiple threads can do multiple read-only operations at the same time.

|                  |     Type     | Other Read-only | Other Modification | Incompatibility Behavior |
|------------------|:------------:|:---------------:|:------------------:|--------------------------|
| `get`            | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `getAsync`       | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `set`            | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `setAsync`       | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `read`           | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `readAsync`      | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `write`          | Modification |   Incompatible  |    Incompatible    | Wait for access          |
| `writeAsync`     | Modification |   Incompatible  |    Incompatible    | Return immediately       |
| `size`           | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `sizeAsync`      | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `iterator`       | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `iteratorAsync`  | Read-only    |    Compatible   |    Incompatible    | Return immediately       |
| `toString`       | Read-only    |    Compatible   |    Incompatible    | Wait for access          |
| `toStringAsync`  | Read-only    |    Compatible   |    Incompatible    | Return immediately       |

<a name="tunnel.serializer"></a>
## `tunnel.Serializer` ##

`tunnel.Serializer` is a class controlling serialization of data. It enabled share-serialization for the following data types by storing only their underlying pointers:

* `torch.*Storage`
* `torch.*Tensor`
* `tds.Hash` or `tds.hash`
* `tds.Vec` or `tds.vec`
*  The above objects inside plain lua tables (including nested tables), such as `nn` modules.

It is used extensively across all `tunnel` data structures. You should not use this class unless you know what you are doing.

The constructor requires no arguments.

```lua
serializer = tunnel.Serializer()
```

<a name="tunnel.serializer.save"></a>
### `storage = serializer:save(object)` ###

Save `object` to `storage`. `storage` is a `torch.CharStorage`.  If `object` is share-serializable, it will store its pointer and add its reference counter by one.

<a name="tunnel.serializer.load"></a>
### `object = serializer:load(storage)` ###

Load `object` from `storage`. `storage` is a `torch.CharStorage`. If `object` is share-serializable, you should not use `storage` to deserialize the same object again.

<a name="tunnel.serializer.retain"></a>
### `object = serializer:retain(storage)` ###

Load `object` from `storage` and retain validity of `storage`. `storage` is a `torch.CharStroage`. If `object` is share-serializable, you can use `storage` to deserialize the same object again.

<a name="tunnel.serializer.swapwrite"></a>
### `serializer.swapWrite()` ###

A static function to swap the metatables of share-serializable classes for writing. Call it again to restore the metatables.

<a name="tunnel.serializer.swapread"></a>
### `serializer.swapRead()` ###

A static function to swap the metatables of share-serializable classes for loading. Call it again to restore the metatables.

<a name="tunnel.serializer.swapretain"></a>
### `serializer.swapRetain()` ###

A static function to swap the metatables of share-serializable classes for retained loading. Call it again to restore the metatables.
