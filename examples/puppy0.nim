import puppy, tables

var data: Table[string, string]

proc getUrl(url: string) =
  echo "starting: ", url
  let html = fetch(url)
  echo "done: ", url, " - ", html.len, " bytes"
  data[url] = html

getUrl("https://github.com/treeform/puppy")
getUrl("https://github.com/treeform/pixie")
getUrl("https://github.com/treeform/vmath")

for url in data.keys:
  echo "* ", url, " - ", data[url].len, " bytes"
