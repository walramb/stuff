#dependencies:
#jQuery
#Underscore.js

halp = {}

#pilfered from stackoverflow
#i have no idea what im doing
hue2rgb = (p,q,t) ->
  if t < 0 then t++
  if t > 1 then t--
  if t < 1/6 then return p+(q-p)*6*t
  if t < 1/2 then return q
  if t < 2/3 then return p+(q-p)*(2/3-t)*6
  return p
hslToRgb = (h,s,l) ->
  if s is 0
    r = g = b = l
  else
    q = if l < 0.5 then l * (1+s) else l+s-l*s
    p = 2*l-q
    r=hue2rgb(p,q,h+1/3)
    g=hue2rgb(p,q,h)
    b=hue2rgb(p,q,h-1/3)
  return [a,b,c].map (n) -> Math.round n*255

halp.color = hslToRgb: hslToRgb


closestpoint = (p, pointarr) ->
  closest = pointarr[0]
  for point in pointarr
    if closest.dist(p) > point.dist(p)
      closest = point
  return closest

#geometry.pointInsidePoly p, points

polygon_and_line_intersect = (candidate,line) ->
  p = new V2d @pos.x, @pos.y
  edges = pointlisttoedges candidate.points
  hits=edges.map (edg) -> line.lineintersect edg
  hits = _.compact hits
  return hits

class Poly
  constructor: (@points=[]) ->

Poly::boundingbox = ->
  xs=@points.map (pt) -> pt.x
  ys=@points.map (pt) -> pt.y
  min = (a,b) -> Math.min a,b
  max = (a,b) -> Math.max a,b
  l=Math.round xs.reduce min
  r=Math.round xs.reduce max
  t=Math.round ys.reduce min
  b=Math.round ys.reduce max
  return makebox V(l,t), V(r-l,b-t), V(0,0)

class Rect
  constructor: (@x,@y,@w,@h) ->
  # axis-aligned rectangles

#anchor is a vector
#bottomcenter = V .5, 1
#topleft =      V  0, 0

Rect::relativetobox = ( anchor ) ->
  V(@x,@y).vadd V(@w,@h).vmul anchor

# equivalent to @relative V .5, .5
Rect::centerpoint = -> V @x+@w/2, @y+@h/2


_Rectmethods =
  containspoint: (p) ->
    @x <= p.x and @y <= p.y and @x+@w >= p.x and @y+@h >= p.y

_.extend Rect::, _Rectmethods

Rect::intersection = (rectb) ->
  # returns a new rect of area shared by both rects, like bool AND
  recta=@
  l=Math.max recta.left(), rectb.left()
  t=Math.max recta.top(), rectb.top()
  r=Math.min recta.right(), rectb.right()
  b=Math.min recta.bottom(), rectb.bottom()
  w=r-l
  h=b-t
  return new Rect l,t,w,h


Rect::strictoverlaps = ( rectb ) ->
  recta=@
  if recta.left() >= rectb.right() or
  recta.top() >= rectb.bottom() or
  recta.right() <= rectb.left() or
  recta.bottom() <= rectb.top()
    return false
  else
    return true

#rename Rect::touching ?
Rect::overlaps = ( rectb ) ->
  recta=@
  if recta.left() > rectb.right() or
  recta.top() > rectb.bottom() or
  recta.right() < rectb.left() or
  recta.bottom() < rectb.top()
    return false
  else
    return true

Rect::bonk = () ->
  @timers.bonk = 6

Rect::tostone = () -> DEPRECATE()

Rect::fixnegative = () ->
  if @w<0
    @x+=@w
    @w*=-1
  if @h<0
    @y+=@h
    @h*=-1

hitboxfilter_OLD = ( hitbox, rectarray ) ->
  rectarray.filter (box) ->
    hitbox.overlaps box

hitboxfilter = ( hitbox, rectarray ) ->
  stats.collisionchecks+= rectarray.length
  res = hitboxfilter_OLD hitbox, rectarray
  #stats.collisionchecks+= res.length
  return res

makebox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  return new Rect truepos.x, truepos.y, dimensions.x, dimensions.y

leftof = (box) -> box.x
rightof = (box) -> box.x+box.w
bottomof = (box) -> box.y+box.h
topof = (box) -> box.y

Rect::left = -> leftof @
Rect::right = -> rightof @
Rect::bottom = -> bottomof @
Rect::top = -> topof @


Rect::issamebox = (b) ->
  return @x is b.x and @y is b.y and @w is b.w and @h is b.h

blocksatpoint = (blocks, p) ->
  blocks.filter (box) -> box.containspoint p

boxtouchingwall = (collidebox) ->
  blockcandidates=hitboxfilter collidebox, WORLD.bglayer
  for block in blockcandidates
    notontop = collidebox.bottom()>block.top()
    if notontop and collidebox.left() < block.left()
      return true
    if notontop and collidebox.right() > block.right()
      return true
  return false

Rect::gethitbox = () -> @


carveoutblock = (b) ->
  #copy because reasons
  block = new Rect b.x, b.y, b.w, b.h
  tocarve=block.allstrictoverlaps()
  for bloke in tocarve
    blockcarve bloke,block
  todelete=block.allstrictoverlaps()
  for bloke in todelete
    WORLD.bglayer = _.without WORLD.bglayer, bloke
    if bloke._pixisprite?
      stage.removeChild bloke._pixisprite


Rect::allstrictoverlaps = ->
  blox=WORLD.bglayer
  return blox.filter (otherblock) => @strictoverlaps otherblock
Rect::alloverlaps = ->
  blox=WORLD.bglayer
  return blox.filter (otherblock) => @overlaps otherblock
Rect::equals = (b) ->
  return @x=b.x and @y=b.y and @w=b.w and @h=b.h


halp.Rect=Rect

###
  xml generation
###

xmlwrap = (tagname,body) ->
  xmltag tagname, undefined, body
###
maketablerow = ( values ) ->
  tds = values.map (v) -> xmlwrap "td", v
  return xmlwrap "tr", tds
jame.maketable = (arrofarr) ->
  domelm = $ '<table>'
  for k,v of arrofarr
    domelm.append maketablerow v
  return domelm
###

root = exports ? this
root.halp = halp
