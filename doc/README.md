<a name="tunnel.doc"></a>
# Tunnel #
Tunnel is a data driven framework for distributed computing in Torch7. It consists of the following classes

* [`tunnel.Block`](#tunnel.block): a thread manager. In tunnel, a block is a group of threads that execute the same function.
* [`tunnel.Share`](#tunnel.share): a shared object wrapper. It can be used to wrap a data object to ensure shared serialization when transferring between threads.
* [`tunnel.Atomic`](#tunnel.atomic): an atomic object wrapper. It can be used to wrap a data object using the [reader-writer lock model](https://en.wikipedia.org/wiki/Readers%E2%80%93writers_problem), with both synchronous and asynchronous interface.
* [`tunnel.Printer`](#tunnel.printer): an atomic printer to standard output.
* [`tunnel.Vector`](#tunnel.vector): an synchronized vector data structure that can be used as an array, a queue, or a stack. It has both synchronous and asynchronous interface.
* [`tunnel.Hash`](#tunnel.hash): a synchronized hash table. It has both synchronous ahd asynchronous interface.

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

`tunnel.Share` is a class that enforces shared serialization for the data it wraps. It utilizes `threads.sharedserialization` for the job, and right now the following data can be share-serialized

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

<a name="tunnel.atomic.read"></a>
### `result = atomic:read(callback)` ###

A synchronous read operation in which `callback` is called by passing `atomic.data` as its argument. The result after executing `callback(atomic.data)` is returned.

`atomic:read()` allows multiple readers (synchronous or asynchronous) to access data, so one must ensure that `callback` should do read-only operations. If some write operation is executing when it attempts to access data, the synchronous reader waits until the writer is finished before executing `callback`. Therefore, a synchronous read operation will always be successful.

<a name="tunnel.atomic.writeasync"></a>
### `result = atomic:writeAsync(callback)` ###

An asynchronous write operation in which `callback` is called by passing `atomic.data` as its argument. If the data access can be acquired successfully, the result after executing `callback(atomic.data)` is returned.

`atomic:writeAsync` attempts to acquire exclusive access to the data when executing `callback`. If there are other writers or readers accessing data, the asynchronous writer returns immediately without executing `callback`. Therefore, an asynchronous write operation may fail.

<a name="tunnel.atomic.readasync"></a>
### `result = atomic:readAsync(callback)` ###

An asynchronous read operation in which `callback` is called by passing `atomic.data` as its argument. if the data access can be acquired successfully, the result after executing `callback(atomic.data)` is returned.

`atomic:readAsync()` allows multiple readers (synchronous or asynchronous) to access data, so one must ensure that `callback` should do read-only operations. If some write operation is executing when it attempts to access data, the asynchronous reader returns immediately without executing `callback`. Therefore, an asynchronous read operation may fail.

The following table summarizes the compatibility and behavior of these four access functions.

|            | Other Readers | Other Writers | Incompatibility Behavior |
|------------|---------------|---------------|--------------------------|
| write      |  Incomptable  |  Incomptable  | Wait for access          |
| read       |   Comptable   |  Incomptable  | Wait for access          |
| writeAsync |  Incomptable  |  Incomptable  | Return immediately       |
| readAsync  |   Comptable   |  Incomptable  | Return immediately       |

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
### `printer:print(...)` ###

A synchronized equivalent of calling `print(...)`. It also synchronizes with `printer:write(...)`.

<a name="tunnel.printer.write"></a>
### `printer:write(...)` ###

A synchronized equivalent of calling `io.write(...)`. It also synchronizes with `printer:print(...)`.

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

<a name="tunnel.hash"></a>
## `tunnel.Hash` ##