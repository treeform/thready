import thready, os, sugar

type ThreadCtx = ref object
  num: int

proc threadFunc(t: ThreadCtx) =
  echo "start", t.num
  for i in 1 .. t.num:
    echo "here ", i, "/", t.num
    sleep(1)

var threads: seq[Thready]
for i in 0 .. 5:
  var t = ThreadCtx()
  t.num = i
  threads.add spawn threadFunc(t)


echo threads
echo "pre wait"
wait2(threads)
echo "after wait"
