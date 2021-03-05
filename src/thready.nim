# import winim, os

# proc threadProc(lpParam: LPVOID): DWORD {.winapi, stdcall.} =
#   for i in 0 .. 100:
#     echo "here"
#     sleep(1)

# var threadId: HANDLE
# var argument: int = 123

# #var threadHandle = 0

# var threadHandle = CreateThread(
#   nil,                   # default security attributes
#   0,                      # use default stack size
#   cast[LPTHREAD_START_ROUTINE](threadProc),       # thread function name
#   cast[LPVOID](argument),          # argument to thread function
#   0,                      # use default creation flags
#   cast[LPDWORD](threadId.addr)
# )

# echo threadHandle

# echo "pre wait"
# WaitForSingleObject(threadHandle, INFINITE)
# echo "after wait"

# var success = CloseHandle(threadHandle)
# echo success

import locks, macros

when not compileOption("threads"):
  {.error: "Only works with --threads:on.".}
when not defined(gcArc):
  {.error: "Only works with --gc:arc or --gc:orc.".}

type
  Thready* = distinct int

var
  threads: array[0..10, Thread[void]]
  threadIdx: int = 0
  mainLock: Lock

template spawn*(body: untyped): Thready =
  ## Starts a new thread.
  acquire(mainLock)
  proc threadProc() =
    {.gcsafe.}:
      body
  createThread(threads[threadIdx], threadProc)
  var ret = threadIdx.Thready
  inc threadIdx
  release(mainLock)
  ret

proc wait*(thready: Thready) =
  ## Makes current thread wait passed thread to finish.
  joinThread(threads[threadIdx.int])

proc wait2*(threadys: seq[Thready]) =
  for t in threadys:
    joinThread(threads[t.int])

proc `$`*(thready: Thready): string =
  "Thready#" & $thready.int

template sync*(body: untyped): untyped =
  ## Synchronize this block/expression.
  ## Only one thread can enter at a time.
  #echo "in sync"
  acquire(mainLock)
  var ret = body
  #echo "out of sync"
  release(mainLock)
  #echo "ret: ", ret
  ret

template sync2*(body: untyped) =
  ## Synchronize this block/expression.
  ## Only one thread can enter at a time.
  #echo "in sync"
  acquire(mainLock)
  body
  #echo "out of sync"
  release(mainLock)
  #echo "ret: ", ret


initLock(mainLock)


proc hasKind(node: NimNode, kind: NimNodeKind): bool =
  for c in node.children:
    if c.kind == kind:
      return true
  return false

proc `[]`(node: NimNode, kind: NimNodeKind): NimNode =
  for c in node.children:
    if c.kind == kind:
      return c
  return nil

proc paramsToObj*(fn: NimNode): NimNode =
  ## Creates a ref object from function parameters.
  echo "paramsToObj: ", fn.treeRepr
  echo fn.getImpl[nnkFormalParams].treeRepr

  result = quote do:
    type ThreadHolder = object
      threadyId: int

  echo result.treeRepr

  for thing in fn.getImpl[nnkFormalParams][1..^1]:
    echo "got: ", thing.treeRepr
    var identDefs = newIdentDefs(ident(thing[0].strVal), thing[1])
    echo "adding: ", identDefs.treeRepr
    result[nnkTypeDef][nnkObjectTy][nnkRecList].add(identDefs)

  echo result.treeRepr

# macro spawn*(body: typed): Thready =
#   ## Starts a new thread.

#   let v = quote do:
#     foo(a.b, c.d)
#   echo v.treeRepr

#   echo body.treeRepr
#   echo body.kind

#   if body.kind != nnkCall:
#    error "Spawn must be called with a function call. Example `span fn(1,2,3)`"

#   var typeDef = paramsToObj(body[0])
#   var typeName = typeDef[nnkTypeDef][nnkIdent]


#   var threadArgs = ident("threadArgs")

#   var call = newNimNode(nnkCall)
#   call.add(body[0])
#   var i = 0
#   for name in body[0].getImpl[nnkFormalParams][1..^1]:
#     echo i, ":", name.treeRepr
#     var dot = newNimNode(nnkDotExpr)
#     dot.add threadArgs
#     dot.add ident(name[0].strVal)
#     call.add dot

#   result = quote do:
#     `typeDef`
#     var threadArgs = cast[ptr `typeName`](alloc(sizeof(`typeName`)))
#     threadArgs.num = 10
#     proc threadProc(threadArgsPtr: pointer) =
#       {.gcsafe.}:
#         var `threadArgs` = cast[`typeName`](threadArgsPtr)
#         `call`
#         (threadArgs)
#     acquire(mainLock)
#     createThread(threads[threadIdx], threadProc, cast[pointer](threadArgs))
#     var ret = threadIdx.Thready
#     inc threadIdx
#     release(mainLock)
#     ret

#   echo result.repr
