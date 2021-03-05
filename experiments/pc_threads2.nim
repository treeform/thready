# Producer consumer with regular nim threads:
import locks, os, random

var r = initRand(2020)

var
  qLock: Lock
  consumers: array[0 .. 9, Thread[void]]
  producers: array[0 .. 9, Thread[void]]

type Work = ref object
  name: string
  id: int
  workUnits: int

var q: seq[Work]

initLock(qLock)

proc producer() {.thread.} =
  while true:
    # at any time randomly create N amount of work
    sleep(100)

    if r.rand(0 .. 1) == 0:
      var work = Work()
      work.id = r.rand(0 .. 100_000)
      work.name = "work" & $work.id
      work.workUnits = r.rand(0 .. 100)

      acquire(qLock)
      {.gcsafe.}:
        q.add(work)
      release(qLock)

      echo "produce: ", work.name

for i in 0 ..< 10:
  createThread(producers[i], producer)

proc consumer() {.thread.} =
  while true:
    acquire(qLock)
    var work: Work
    {.gcsafe.}:
      if q.len == 0:
        echo "exit"
        release(qLock)
        return
      work = q.pop()
    release(qLock)

    echo "consume: ", work.name

    sleep(100) # do some work every second


for i in 0 ..< 10:
  createThread(consumers[i], consumer)

sleep(10000)
#joinThreads(consumers)
