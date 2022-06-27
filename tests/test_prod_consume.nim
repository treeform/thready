import thready, os

var q: seq[int]

proc producer(i: int) =
  for j in 0 .. i:
    sleep(1000) # create some work every seconds
    let id = 100 * i + j
    echo "add work ", id
    sync(q):
      q.add(100 * i + j)

proc consumer() =
  while true:
    sync(q):
      if q.len > 0:
        var id = q.pop()
        echo " do work ", id
    sleep(1000) # do some work every second

for i in 0 ..< 4:
  discard spawn producer(i)

for i in 0 ..< 4:
  discard spawn consumer()

wait()
