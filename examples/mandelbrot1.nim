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
