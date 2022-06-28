import std/random, std/sha1, strutils, thready

randomize()

const difficulty = "0000"
var blockChain: seq[string]
blockChain.add("5F603E799CBD068591F2F4A0F1327A5D7D6A2000")

echo "starting solver"

proc hasher(id: int) {.gcsafe.} =
  var r = initRand()
  while true:
    var prevHash: string
    sync(blockChain):
      if blockChain.len > 20:
        return
      prevHash = blockChain[^1]
    for _ in 0 ..< 1000:
      let salt = r.rand(int.high)
      let hash = $secureHash(prevHash & $salt)
      if hash.endsWith(difficulty):
        sync(blockChain):
          if blockChain[^1] == prevHash:
            blockChain.add(hash)
            echo id, " solved the hash"
          else:
            echo id, " solved but too late"
        break

for id in 0 ..< 10:
  discard spawn hasher(id)

wait()

for hash in blockChain:
  echo "* ", hash
