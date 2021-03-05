# Producer consumer with thready threads:
import thready2

var count: int



proc consumer() =
  #echo count
  inc count

var consumers: seq[Thready]
for i in 0 ..< 10000:
  consumers.add spawn consumer()

wait(consumers)

echo "f:", count
