import std/tasks, std/locks, os, macros

const
  maxThreads = 16
  maxLocks = 256

var
  lockCounter {.compiletime.}: int

type
  Threadlet = ref object
    task: Task
    done: bool

var
  globalThreads: array[maxThreads, Thread[int]]
  globalTasks: seq[Threadlet]
  globalTasksLock: Lock
  globalLocks: array[maxLocks, Lock]

proc workerFunction(i: int) {.thread.} =
  while true:
    var
      hasTask = false
      threadlet: Threadlet
    acquire(globalTasksLock)
    {.gcsafe.}:
      if globalTasks.len > 0:
        hasTask = true
        threadlet = globalTasks.pop()
    release(globalTasksLock)

    if hasTask:
      threadlet.task.invoke()
      threadlet.done = true

    sleep(0)


template spawn(something: untyped): Threadlet =
  var t = Threadlet()
  t.task = toTask something
  acquire(globalTasksLock)
  globalTasks.add t
  release(globalTasksLock)
  t

macro sync(body: untyped) =
  let stmts = quote do:
    acquire(globalLocks[`lockCounter`])
    `body`
    release(globalLocks[`lockCounter`])
  echo repr stmts
  inc lockCounter
  return stmts

proc wait(t: Threadlet) =
  while not t.done:
    sleep(0)

proc wait(threadlets: openarray[Threadlet]) =
  for t in threadlets:
    wait(t)

proc initThready() =
  initLock(globalTasksLock)
  for i in 0 ..< maxLocks:
    initLock(globalLocks[i])
  for i in 0 ..< maxThreads:
    createThread(globalThreads[i], workerFunction, i)


block:

  initThready()

  # proc hello(what: string) =
  #   echo "hello " & what

  # proc add(a, b: int) =
  #   echo "add: " & $(a + b)

  # discard spawn hello("world")
  # discard spawn hello("nim")
  # discard spawn hello("threads")
  # discard spawn add(2, 2)


  proc hello(what: string) =
    sync:
      for i in 0 ..< 10:
        echo i, " hello " & what

  proc hello2(what: string) =
    sync:
      for i in 0 ..< 10:
        echo i, " hello " & what

  let
    a = spawn hello("world")
    b = spawn hello("nim")
    c = spawn hello2("threads")

  wait([a, b, c])
