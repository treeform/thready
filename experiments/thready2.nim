import locks
export locks
import os
export sleep

type Thready* = distinct int

var
  globalLock*: Lock
  threadyCount*: int
  threads*: array[0..20000, Thread[Thready]]
  threadFns*: array[0..20000, proc(){.cdecl.}]

initLock(globalLock)

proc threadFunction(thready: Thready) {.thread.} =
  {.gcsafe.}:
    threadFns[thready.int]()

template sync*(lock: Lock, body: untyped) =
  try:
    acquire(lock)
    {.gcsafe.}:
      body
  finally:
    discard
    release(lock)

template sync*(body: untyped) =
  sync(globalLock, body)

template spawn*(function: untyped): Thready =
  var thready: Thready
  sync:
    thready = Thready(threadyCount)
    inc threadyCount
    proc closureFn() {.gensym, cdecl.} =
      function
    threadFns[thready.int] = closureFn
    createThread(threads[thready.int], threadFunction, thready)
  thready

proc wait*(thready: Thready) =
  joinThread(threads[thready.int])

proc wait*(threadys: seq[Thready]) =
  for thready in threadys:
    wait(thready)
