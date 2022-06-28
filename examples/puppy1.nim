import thready, puppy, tables

var data: Table[string, string]

proc getUrl(url: string) =
  echo "starting: ", url
  let html = fetch(url)
  echo "done: ", url, " - ", html.len, " bytes"
  sync(data): # <-- synchronize access to data
    data[url] = html

# Spawn the threads (and discard the returned Threadlet)
discard spawn getUrl("https://github.com/treeform/puppy")
discard spawn getUrl("https://github.com/treeform/pixie")
discard spawn getUrl("https://github.com/treeform/vmath")

wait() # <-- wait for 3 spawned threads to finish

# We could put data in a sync block, but because we know
# that all threads have finished there is no need.
for url in data.keys:
  echo "* ", url, " - ", data[url].len, " bytes"
