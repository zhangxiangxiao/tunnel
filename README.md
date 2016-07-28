# Tunnel

Tunnel is a data driven framework for distributed computing in Torch 7. It consists of two part -- a set of synchronous data structures, and a manager for threads. Parallelization on a single machine is taken care of by multi-threading using the threads package. For across-machine prallelization, the data structure server Redis is used. Tunnel abstracts single- and multi- machine data structures away using similar interfaces, enabling programming of distributed machine learning algorithms without a single line for synchronization.

## Why data driven?

Machine learning systems are intrinsically data-driven. There is data everywhere -- including training and testing samples, the model parameters, and various state used in different algorithms. This means that by carefully designing and implementing various synchronized data structures, we can make it possible to program distributed machine learning systems without a single line of synchronization code. It is in contrast with program-driven methodology where the programmer has to take care of mutexes, condition variables, semaphores and message passing himself.
