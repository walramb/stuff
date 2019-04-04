#based on code by Ilmari Heikkinen
#http://www.html5rocks.com/en/tutorials/canvas/imagefilters/

Filters = {}

Filters.getCanvas = (w,h) ->
  c = $("<canvas>")[0]
  c.width = w
  c.height = h
  return c

Filters.getPixels = (img) ->
  c = Filters.getCanvas img.naturalWidth, img.naturalHeight
  ctx = c.getContext '2d'
  ctx.drawImage img, 0, 0
  return ctx.getImageData 0, 0, c.width, c.height

Filters.filterImage = ( filter, image, varargs... ) ->
  varargs.unshift @.getPixels image
  return filter.apply null, varargs

Filters.grayscale = (pixels,args) ->
  d = pixels.data
  i=0
  while i<d.length
    r=d[i]
    g=d[i+1]
    b=d[i+2]
    v = 0.2*r + 0.7*g + 0.07*b
    d[i]=d[i+1]=d[i+2]=v
    i+=4
  return pixels

root = exports ? this
root.Filters = Filters

