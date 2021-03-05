# Producer consumer with thready threads:
import thready2

var q: seq[int]

for i in 0 ..< 20:
  echo "produce: ", i
  q.add(i)

proc consumer() =
  while true:
    sync:
      if q.len == 0:
        echo "exit"
        return
      var i = q.pop()
      echo "consume: ", i
    sleep(1000) # do some work every second

var consumers: seq[Thready]
for i in 0 ..< 10:
  consumers.add spawn consumer()

wait(consumers)
