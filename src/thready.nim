import std/tasks, std/locks, os, macros, tables
export tasks

const
  maxThreads = 16
  maxLocks = 256

var
  lockCounter {.compiletime.}: int
  lockNames {.compiletime.}: Table[string, int]

type
  Threadlet* = ref object
    task: Task
    done: bool

var
  globalThreads: array[maxThreads, Thread[int]]
  globalThreadsRunning: int
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
        inc globalThreadsRunning
    release(globalTasksLock)

    if hasTask:
      threadlet.task.invoke()
      threadlet.done = true
      dec globalThreadsRunning

    sleep(0)

template spawn*(something: untyped): Threadlet =
  var t = Threadlet()
  t.task = toTask something
  acquire(globalTasksLock)
  globalTasks.add t
  release(globalTasksLock)
  t

macro sync*(body: untyped) =
  let stmts = quote do:
    acquire(globalLocks[`lockCounter`])
    {.gcsafe.}:
      `body`
    release(globalLocks[`lockCounter`])
  echo repr stmts
  inc lockCounter
  return stmts

macro sync*(name, body: untyped) =
  let nameStr = repr(name)
  if nameStr notin lockNames:
    lockNames[nameStr] = lockCounter
    inc lockCounter
  let lockIndex = lockNames[nameStr]
  let stmts = quote do:
    acquire(globalLocks[`lockIndex`])
    {.gcsafe.}:
      `body`
    release(globalLocks[`lockIndex`])
  echo repr stmts
  return stmts

proc wait*() =
  while true:
    acquire(globalTasksLock)
    if globalTasks.len == 0 and globalThreadsRunning == 0:
      break
    release(globalTasksLock)
    sleep(0)

proc wait*(t: Threadlet) =
  while not t.done:
    sleep(0)

proc wait*(threadlets: openarray[Threadlet]) =
  for t in threadlets:
    wait(t)

initLock(globalTasksLock)
for i in 0 ..< maxLocks:
  initLock(globalLocks[i])
for i in 0 ..< maxThreads:
  createThread(globalThreads[i], workerFunction, i)
