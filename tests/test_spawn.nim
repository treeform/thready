# Producer consumer with thready threads:
import thready

proc msger(msg: string, number: int) =
  sync:
    echo "msg: ", msg, " ", number

let t1 = spawn msger("hi there", 123)
let t2 = spawn msger("are you ok?", 456)

wait(t1)
wait(t2)
