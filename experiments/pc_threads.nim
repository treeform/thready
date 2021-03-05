# Producer consumer with regular nim threads:
import locks, os

var
  qLock: Lock
  p: Thread[void]
  consumers: array[0 .. 9, Thread[void]]

var q: seq[int]

initLock(qLock)

proc producer() {.thread.} =
  acquire(qLock)
  {.gcsafe.}:
    for i in 0 ..< 20:
      echo "produce: ", i
      q.add(i)
  release(qLock)

proc consumer() {.thread.} =
  while true:
    acquire(qLock)
    {.gcsafe.}:
      if q.len == 0:
        echo "exit"
        release(qLock)
        return
      var i = q.pop()
      echo "consume: ", i
    release(qLock)
    sleep(1000) # do some work every second

createThread(p, producer)

for i in 0 ..< 10:
  createThread(consumers[i], consumer)

joinThread(p)
joinThreads(consumers)
