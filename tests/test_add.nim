# Producer consumer with thready threads:
import thready

var count: int

proc adder(amount: int) =
  sync:
    echo amount
    count += amount

var workers: seq[Threadlet]
for i in 0 ..< 10:
  workers.add spawn adder(amount = i)

wait(workers)

var total = 0
for i in 0 ..< workers.len:
  total += i

echo "count = ", count, " should be ", total

doAssert count == total
