# Producer consumer with thready threads:
import thready

proc messenger(number: int) =
  echo number

let t2 = spawn messenger(1.int)
wait(t2)
