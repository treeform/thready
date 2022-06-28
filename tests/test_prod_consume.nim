import thready, os

var q: seq[int]

proc producer(i: int) =
  for j in 0 .. i:
    # create some work
    let id = 100 * i + j
    echo "add work ", id
    sync(q):
      q.add(100 * i + j)
    sleep(100)

proc consumer() =
  while true:
    # do some work
    var
      id: int
      hasWork: bool
    sync(q):
      if q.len > 0:
        id = q.pop()
        hasWork = true
    if hasWork:
      echo " do work ", id
    else:
      sleep(100)

for i in 0 ..< 4:
  discard spawn producer(i)

for i in 0 ..< 4:
  discard spawn consumer()

proc exit() =
  sleep(1000)
  sync(q):
    if q.len > 0:
      quit("some work was not done")
    else:
      quit(0)
discard spawn exit()

wait()
