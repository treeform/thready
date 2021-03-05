import thready, os

proc threadFunc(num: int) =
  echo "num:", num
  for i in 0 .. num:
    echo "here"
    sleep(1)
var t = spawn threadFunc(10)
echo t
echo "pre wait"
wait(t)
echo "after wait"
