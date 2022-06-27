# Producer consumer with thready threads:
import thready

var count: int

proc incer() =
  sync:
    inc count

var consumers: seq[Threadlet]
for i in 0 ..< 10000:
  consumers.add spawn incer()

wait(consumers)

echo "count = ", count
doAssert count == 10000
