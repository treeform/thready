import std/random, std/sha1, strutils, thready

randomize()

const difficulty = "0000"
var blockChain: seq[string]
blockChain.add("5F603E799CBD068591F2F4A0F1327A5D7D6A2000")

echo "starting solver"

proc hasher() =
  var r = initRand()
  while true:
    var prevHash: string
    if blockChain.len > 20:
      return
    prevHash = blockChain[^1]
    let salt = r.rand(int.high)
    let hash = $secureHash(prevHash & $salt)
    if hash.endsWith(difficulty):
      echo "solved the hash"
      blockChain.add(hash)

hasher()

for hash in blockChain:
  echo "* ", hash
