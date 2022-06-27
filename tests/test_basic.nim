import thready

proc hello(what: string) =
  sync:
    for i in 0 ..< 10:
      echo i, " hello " & what

proc hello2(what: string) =
  sync:
    for i in 0 ..< 10:
      echo i, " hello " & what

let
  a = spawn hello("world")
  b = spawn hello("nim")
  c = spawn hello2("threads")

wait([a, b, c])
