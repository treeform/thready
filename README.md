# Thready - a better thread API.

⚠️ WARNING: This library is a WIP and not ready to be used yet. ⚠️

Aim of thready is to make working with threads as simple as possible. This library will only work with --gc:arc or --gc:orc. No other GCs are supported.

Thready distills complex topic of threads to 3 main concepts:

* `spawn` - to create new threads.
* `wait` - to wait for other threads to finish.
* `sync` - enter a synchronization block no other thread can enter.

How to create a thread?

```nim
var t = spawn foo(a, b, c)
```

The `a`, `b`, `c` and be any nim type from generic ref object to a pointer. You get thread `t: Thready` back.

You can do anything with `t` - the thread you get back - you can pass it around, hash it, print it. Its just a `int` id of the thread.

Main thing you can do wit the `t` you get back is to `wait` for it. You can block your current thread and wait for `t` to finish. You can also give `wait` a list of threads to block for.

How do threads communicate? Through the `sync` block and regular nim objects. Sync block ensures that only one thread can enter the `sync` block and the rest will block. Its basically a scope lock. The `sync` can take any number of ref objects and it will block if any of the objects are locked by another `sync` block.

```nim
var q: seq[int]

proc producer(i: int) =
  sync(q):
    for j in 0 .. i:
      sleep(1000) # create some work every seconds
      q.add(j)

proc consumer() =
  while true:
    sync(q):
      if q.len == 0:
        return
      var i = q.pop()
      sleep(1000) # do some work every second
      q.add(i + 1)

for i in 0 .. 10:
  spawn producer(i)

var threads: seq[Thready]
for i in 0 .. 10:
  threads.add spawn consumer()

wait threads
```
