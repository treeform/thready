# Producer consumer with regular nim threads:
import locks, os

var
  qLock: Lock
  consumers: array[0 .. 9, Thread[void]]

type RefObject = ref object
  name: string
  next: RefObject

var q: seq[RefObject]

initLock(qLock)

for i in 0 ..< 20:
  echo "produce: ", i
  q.add(RefObject(name: "name" & $i))

proc consumer() {.thread.} =
  while true:
    acquire(qLock)
    var refObject: RefObject
    {.gcsafe.}:
      if q.len == 0:
        echo "exit"
        release(qLock)
        return
      refObject = q.pop()
    release(qLock)

    refObject.next = RefObject()
    sleep(100) # do some work every second
    echo "consume: ", refObject.name

for i in 0 ..< 10:
  createThread(consumers[i], consumer)

joinThreads(consumers)
