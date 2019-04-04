body=$("body")

V = (x,y) -> new V2d x,y

#V = _VectorLib.V2D
#matrixtransform = _VectorLib.matrixtransform

degstorads = ( deg ) -> deg * Math.PI/180

class Entity

rotate2d = ( vec, deg ) ->
  theta = degstorads deg
  matrix=
  [[Math.cos(theta),-Math.sin(theta)]
  [Math.sin(theta),Math.cos(theta)]]
  newv = matrixtransform matrix, [vec.x, vec.y]
  return V newv[0], newv[1]

cornerstorect = ( a, b ) ->
  l=Math.min a.x, b.x
  r=Math.max a.x, b.x
  t=Math.min a.y, b.y
  b=Math.max a.y, b.y
  return new Rect V(l,t), V(r,b)

class Rect
  constructor: (@left,@top,@bottom,@right) ->
  Object.defineProperties @prototype,
    width: get: -> @right-@left
    height: get: -> @bottom-@top
    area: get: -> @width*@height
    perimeter: get: -> (@width+@height)*2

Rect::overlap = ( other ) ->
  l=Math.max @.left, other.left
  r=Math.min @.right, other.right
  t=Math.max @.top, other.top
  b=Math.min @.bottom, other.bottom
  new Rect l,t,b,r

class Line
  constructor: ( @from=V(), @to=V() ) ->
class Tracer extends Line
class LineDef extends Line

Line::intersection = (lineb) ->
  p = @loc
  r = @to.sub p
  q = lineb.loc
  s = lineb.to.sub q
  t = q.sub(p).cross2d(s) / r.cross2d s
  u = q.sub(p).cross2d(r) / r.cross2d s
  if t <= 1 and t >= 0 and u <= 1 and u >= 0
    return p.vadd r.nmul t
  return null

#based on an implementation by metamal on stackoverflow
HitboxRayIntersect = ( rect, line ) ->
  minx = line.loc.x
  maxx = line.to.x
  if line.loc.x > line.to.x
    minx=line.to.x
    maxx=line.loc.x
  maxx = Math.min maxx, rect.bottomright.x
  minx = Math.max minx, rect.topleft.x
  if minx > maxx
    return false
  miny = line.loc.y
  maxy = line.to.y
  dx = line.to.x-line.loc.x
  if Math.abs(dx) > 0.0000001
    a=(line.to.y-line.loc.y)/dx
    b=line.loc.y-a*line.loc.x
    miny=a*minx+b
    maxy=a*maxx+b
  if miny > maxy
    tmp=maxy
    maxy = miny
    miny = tmp
  maxy=Math.min maxy, rect.bottomright.y
  miny=Math.max miny, rect.topleft.y
  if miny>maxy
    return false
  return true

randangle = () -> Math.random()*360

ricochet = ( v, n ) ->
  # projectile of velocity v
  # wall with surface normal n
  #split v into components u perpendicular to the wall and w parallel to it
  #u=(v*n/n*n)n
  u = n.nmul v.dot2d(n) / n.dot2d(n)
  #w=v-u
  w = v.sub u
  # friction f
  # coefficient of restitution r
  # v' = f w - r u
  vprime = w.sub u
  return vprime

getLineIntersection = ( linea, lineb ) ->
  p = linea.from
  r = linea.to.vsub p
  q = lineb.from
  s = lineb.to.vsub q
  t = q.vsub(p).cross(s) / r.cross s
  u = q.vsub(p).cross(r) / r.cross s
  if t <= 1 and t >= 0 and u <= 1 and u >= 0
    return p.vadd r.nmul t
  return null


Tracer::intersectlocs = () ->
  allLineDefs = gameworld.getLineDefs()
  results = ( getLineIntersection( @, linedef ) for linedef in allLineDefs )
  intersections = results.filter (n) -> n isnt null
  return intersections

Tracer::intersectwalls = () ->
  allLineDefs = gameworld.getLineDefs()
  intersections = allLineDefs.filter (ld) => getLineIntersection( @, ld ) isnt null
  return intersections

firstwallhitloc = ( trace, intersections  ) ->
  fromloc = trace.loc
  firsthit = intersections.reduce ( prev, curr ) ->
    if fromloc.dist(prev) > fromloc.dist(curr)
      return curr
    else return prev
  return firsthit

firetracer = ( fromloc, dir ) ->
  tracerange = 500
  toloc = fromloc.vadd dir.norm().nmul tracerange
  trace = new Tracer( fromloc, toloc )
  intersections = trace.intersectlocs()
  if intersections.length > 0
    firsthit = firstwallhitloc trace, intersections
    trace = new Tracer( trace.loc , firsthit )
  return trace

entfirebullet = ( ent, dir ) ->
  bulletrange = 200
  
  fromloc = ent.loc.nadd 0
  #some scatter
  dir = dir.vadd( randompoint().nsub(1/2).ndiv(4) ).norm()
  trace = firetracer fromloc, dir
  
  allactors = gameworld.entitylist.filter (ent) -> ent instanceof Actor
  targets = allactors.filter (actor) -> actor isnt ent
  hits = trace.checkEnts targets
  hits.forEach (hitent) ->
    bullethit hitent, trace
  gameworld.addent trace

LineDef::normal = ->
  wallnormal = @to.sub(@loc).norm()
  wallnormal = V -wallnormal.y, wallnormal.x
  return wallnormal

class Polygon extends Entity
  constructor: (@points) ->
    @loc = @points[0]

pointlisttoedges = ( parr ) ->
  edges=[]
  prev = parr[parr.length-1]
  for curr,i in parr
    edges.push new Tracer prev,curr
    prev=curr
  return edges

pointInsidePoly = ( p, poly ) ->
  # poly type: simply an array of points
  # a point P is inside a polygon iff the no. of poly edges intersecting
  # a line from P to an arbitrary point outside the poly is odd
  trace = new Tracer p, p.vadd V 10000,0
  edges=pointlisttoedges poly
  results = ( getLineIntersection( trace, e ) for e in edges )
  intersections = results.filter (n) -> n isnt null
  if intersections.length % 2 == 1
    return true
  return false


class Graph
  constructor: ->
    @nodes = []
    @edges = []


normtoangle = ( vec ) -> Math.atan2( vec.x, vec.y  )*180/Math.PI
angletonorm = ( degs ) ->
  augh = degstorads degs
  return V Math.sin( augh ), Math.cos( augh )


#GEOMETRY
class Point
  constructor: ( @pos ) ->
class LineSegment
  constructor: ( @startpoint, @endpoint ) ->
class Rect extends Entity
  constructor: ( @topleft, @bottomright ) ->
    @loc = @topleft
  draw: () ->
    size = @bottomright.sub @topleft
    return "<rect x=#{@topleft.x} y=#{@topleft.y} width=#{size.x} height=#{size.y} stroke=magenta fill=none/>"
Rect::containspoint = ( pt ) ->
  if @topleft.x > pt.x then return false
  if @bottomright.x < pt.x then return false
  if @topleft.y > pt.y then return false
  if @bottomright.y < pt.y then return false
  return true
class Square extends Entity
  constructor: ( @topleft, @bottomright ) ->
    @loc = @topleft
    @age = 0
  tick: () ->
    @age++
    if @age > 4
      @kill()
  draw: () ->
    size = @bottomright.sub @topleft
    return "<rect x=#{@topleft.x} y=#{@topleft.y} width=#{size.x} height=#{size.y} stroke=magenta fill=none/>"

entDist = ( enta, entb ) -> enta.loc.dist entb.loc
entDir = ( enta, entb ) -> enta.loc.dir entb.loc

vectorindex = ( array, vector ) ->
  res = -1
  for v,i in array
    if vector.dist(v)==0
      res = i
  return res

#convert edge soup to polygons
edgestopolys = ( edges  ) ->
  polys = []
  restedges = edges.map (e) ->
    a=V e[0].x, e[0].y
    b=V e[1].x, e[1].y
    return [a,b]
  for edge,i in restedges
    a=edge[0]
    b=edge[1]
    sploiced = false
    for pol,i in polys
      ia = vectorindex pol, a
      ib = vectorindex pol, b
      len = pol.length
      if ib == 0 or ia == 0 or ib == len-1 or ia == len-1
        sploiced = true
      if ia == 0
        pol.splice 0, 0, b
        break
      if ib == 0
        pol.splice 0, 0, a
        break
      if ia == len-1
        pol.splice len, 0, b
        break
      if ib == len-1
        pol.splice len, 0, a
        break
    if sploiced == false then polys.push edge
  return polys

geometry={}
geometry.pointInsidePoly = pointInsidePoly

root = exports ? this
root.geometry = geometry


