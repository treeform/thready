# Thready - a simple thread API.

⚠️ WARNING: This library is a WIP and not ready to be used yet. ⚠️

Aim of `thready` is to make working with threads as simple as possible. This is not most feature proof, the fastest nor does it prevents deadlocks.

But it is the simplest.

`thready` distills complex topic of threads into 3 main concepts:

* `spawn` - to create new threads.
* `sync` - enter a synchronization block no other thread can enter.
* `wait` - to wait for other threads to finish.

⚠️ This library currently only works with `--mm:arc` and `--threads:on`.

There are many different ways to do threading, there is no one-fits-all solution. There are threading via:
* **message-passing** - easy to reason about can be slow if copying large message. Also requires restructuring your program.
* **lock-free data-structures** - great for performance but can be really hard. Requires learning new ways of doing things and requires restructuring your program.
* **locks** - *this library* - good for quick one off things. The old fashioned way. Can have many threads share some data structure, easy to reason about, not the most performant with 100s of threads and when complex enough can deadlock.

Hopefully with `thready` you can just bolt on threading here and there, when you need some thing quickly. Especially when your threading needs are minimal.

## How to create a new threads?

```nim
var t = spawn foo(a, b, c)
```

The `a`, `b`, `c` and be any nim type, and you get thread `t: Threadlet` back. `Threadlet` is what `thready` calls a task or thread in progress.

The main thing you can do with `t` is pass it around and to call `.wait()` on it.
Which would block your current thread and wait for `t` to finish.

## How do threads communicate?

```nim
sync:
  ..do things..

sync(something):
  ..do things..
```

When multiple threads touch the same Nim data structure bad things can happen. Sync command ensures that only one thread can enter the `sync:` block and the rest will block. This is where you can update your object, any object an including `int`, `string`, `seq` and even `table`.

Without any parameters it creates a scope lock.

But often you want multiple places to share a lock, simply give it a name - usually in the form of the objects you are synchronizing:
```nim
sync(q):
  q.add(1)
```
Then in some other part of the code:
```nim
sync(q):
  q.pop()
```

You always want your `sync` blocks to lock the smallest amount of code and for the shortest amount of time. Ideally you only lock when you need to update some thing while most of the work is done outside the `sync` blocks.

Be careful though if you operate on the same data structure from two threads as odd things and crashes will happen. You must put them all in a `sync` block.

## How to block on threads?

```nim
wait()
wait(t)
wait([t1, t2, t3])
```

`wait(t)` Will block until `t` is finished.
Likewise `wait([..])` will wait for all of the threads in a `seq` or `array` to finish.

If you don't wait for any thread your main thread can potentially exit before all threads are finished running.
`wait()` with no arguments just waits for all threads to finish.

## Tutorial - Puppy

Lets say you have a program that does some thing that either blocks io or requires CPU.
Lets say you are already downloading 3 webpages with puppy and get a table in the end:

```nim
import thready, puppy, tables

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
```

If you run the program you can see that it downloads one file after the other:
```
starting: https://github.com/treeform/puppy
done: https://github.com/treeform/puppy - 165890 bytes
starting: https://github.com/treeform/pixie
done: https://github.com/treeform/pixie - 226944 bytes
starting: https://github.com/treeform/vmath
done: https://github.com/treeform/vmath - 178033 bytes
* https://github.com/treeform/vmath - 178033 bytes
* https://github.com/treeform/pixie - 226944 bytes
* https://github.com/treeform/puppy - 165890 bytes
```

Well now you want to do this in parallel.

First add a `spawn` around your functions to kick them off in different threads, so that they can go in parallel.

Then simply add a `sync(data):` block around were you access data. Make sure the sync blocks are pretty small and self contained.

Finally add a `wait()` call after you start all the threads, so that you can wait for all of them to finish.
When your waiting is more complex you can get the actual `Threadlet` objects and wait on them. But for most programs its not really needed.

Your code should look like this:

```nim
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
```

When you run it you should see that now it downloads the html documents in parallel:

```
starting: https://github.com/treeform/puppy
starting: https://github.com/treeform/pixie
starting: https://github.com/treeform/vmath
done: https://github.com/treeform/puppy - 171422 bytes
done: https://github.com/treeform/pixie - 226937 bytes
done: https://github.com/treeform/vmath - 178033 bytes
* https://github.com/treeform/vmath - 178033 bytes
* https://github.com/treeform/pixie - 226937 bytes
* https://github.com/treeform/puppy - 171422 bytes
```

> Note: You could have used `{.async.}` to do similar download, but async does not support DNS async (yes its blocks on DNS) and it does not support gzip encoding (which it would also block on as its single threaded).

## Tutorial - Pixie

Here we will draw mandelbrot - a CPU heavy task.

![mandelbrot](examples/mandelbrot1.png)

Without threads, but with drawing each image in a 100x100 tile:

```nim
import pixie

proc mandelbrot(uv: Vec2): Color =
  var o = vec4(0, 0, 0, 0)
  var zoom = (uv / 700.0 - 0.2) * 2
  while o.w < 98.0:
    o.w += 1
    let v = 0.55f - mat2(-o.y, o.x, o.x, o.y) * vec2(o.y, o.x) + zoom
    o.x = v.x
    o.y = v.y
  return color(o.x + 1f, o.y, 0, 1.0)

var image = newImage(1000, 1000)

proc drawTile(uv: Vec2) =
  var tile = newImage(100, 100)
  for y in 0 ..< 100:
    for x in 0 ..< 100:
      tile[x, y] = mandelbrot(uv + vec2(x.float32, y.float32) - vec2(500, 500))
    image.draw(tile, translate(uv))

for by in 0 ..< 10:
  for bx in 0 ..< 10:
    let pos = vec2(by.float32*100, bx.float32*100)
    drawTile(pos)

image.writeFile("examples/mandelbrot0.png")
```

Then lets add some threads:
* add `sync(image):` around the image access.
* add `discard spawn` to kick off the tile drawing function.
* add `wait()` to wait for tile drawing to finish.

This is how it looks:

```nim
import thready, pixie

proc mandelbrot(uv: Vec2): Color =
  var o = vec4(0, 0, 0, 0)
  var zoom = (uv / 700.0 - 0.2) * 2
  while o.w < 98.0:
    o.w += 1
    let v = 0.55f - mat2(-o.y, o.x, o.x, o.y) * vec2(o.y, o.x) + zoom
    o.x = v.x
    o.y = v.y
  return color(o.x + 1f, o.y, 0, 1.0)

var image = newImage(1000, 1000)

proc drawTile(uv: Vec2) =
  var tile = newImage(100, 100)
  for y in 0 ..< 100:
    for x in 0 ..< 100:
      tile[x, y] = mandelbrot(uv + vec2(x.float32, y.float32) - vec2(500, 500))

  sync(image):
    image.draw(tile, translate(uv))

for by in 0 ..< 10:
  for bx in 0 ..< 10:
    let pos = vec2(by.float32*100, bx.float32*100)
    discard spawn drawTile(pos)

wait()

image.writeFile("examples/mandelbrot1.png")
```
