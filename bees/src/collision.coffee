# AABB collisions
# dependencies: QuadTree.coffee

$body = $ 'body'

$body.append $ '<p>fug</p>'

screensize = x: 640, y: 480

renderer = PIXI.autoDetectRenderer screensize.x, screensize.y
stage=new PIXI.Stage 0xcccccc

$body.append renderer.view

class PhysElem
  constructor: () ->
    @vel = x: 0, y: 0
    @pos = x: 0, y: 0
    @size = x: 32, y: 32
PhysElem::overlaps = (other) ->
  if other.pos.x > (@pos.x+@size.x) or
  other.pos.y > (@pos.y+@size.y) or
  (other.pos.x+other.size.x) < @pos.x or
  (other.pos.y+other.size.y) < @pos.y
    return false
  else
    return true

# this is where the magic happens if you want to
# insert a different type of object
# quads are numbered counterclockwise 
# starting with 0 in upper right for some reason
# -1 if object doesnt fit in a quadrant
QuadTree::getindex = ( rect ) ->
  index=-1
  xmid = @bounds.x + @bounds.w/2
  ymid = @bounds.y + @bounds.h/2
  #fits = rect.w <@bounds.w/2 and rect.h < @bounds.h/2
  #if not fits then return -1
  istop = rect.y+rect.h < ymid
  isbot = rect.y > ymid
  isleft = rect.x+rect.w < ymid
  isright = rect.x > ymid
  if istop and isright then index=0
  if istop and isleft then index=1
  if isbot and isleft then index=2
  if isbot and isright then index=3
  return index


class PhysGroup
  constructor: () ->
    @children = []
    @domain = x: 0, y: 0, w: 640, h: 480
    @tree = new QuadTree 0, @domain
  addchild: (child) ->
    @children.push child
PhysGroup::rebuildtree = ->
  @tree = new QuadTree()
  @children.forEach (child) =>
    @tree.insert PHYSOBJTORECT child

PHYSOBJTORECT = (child) ->
  fuck = { x: child.pos.x, y: child.pos.y, w: child.size.x, h: child.size.y, LINK: child }
  return fuck
QuadTree::grafics = ->
  grafic=new PIXI.Graphics()
  color = 0x0000ff-@level*8
  grafic.lineStyle 1, color, 1
  pad = -@level*2
  grafic.drawRect @bounds.x-pad, @bounds.y-pad, @bounds.w+pad, @bounds.h+pad
  stage.addChild grafic
  _.invoke @subnodes, 'grafics'

PhysGroup::grafics = ->
  @tree.grafics()

PhysElem :: integrate = ->
#euler method a shit
  @pos.x += @vel.x
  @pos.y += @vel.y
PhysElem :: wraparound = ->
  @pos.x = @pos.x % 640
  @pos.y = @pos.y % 480

PhysGroup::tick = ->
  @grafics()
  @colls = []
  @children.forEach (child) ->
    child.integrate()
    child.wraparound()
  @rebuildtree()
  @children.forEach (child) =>
    candidates = @tree.retrieve PHYSOBJTORECT child
    candidates=candidates.map (cand) -> cand.LINK
    newcolls = _.filter candidates, (candidate) -> child.overlaps candidate
    child.iscolliding = newcolls.length>1

physobjs=new PhysGroup()

[0..100].forEach ->
  elm=new PhysElem()
  elm.pos.x = Math.random()*640
  elm.pos.y = Math.random()*480
  elm.size.x = Math.random()*50
  elm.size.y = Math.random()*50
  elm.vel.x = Math.random()*10
  elm.vel.x = Math.random()*3
  physobjs.addchild elm

physobjdraw = (obj)  ->
  grafic=new PIXI.Graphics()
  [w,h]=[obj.size.x,obj.size.y]
  color = 0x00ff00
  if obj.iscolliding
    color = 0xff0000
  grafic.lineStyle 1, color, 1
  grafic.drawRect obj.pos.x, obj.pos.y, obj.size.x, obj.size.y
  stage.addChild grafic


animate = ->
  stage=new PIXI.Stage()
  physobjs.tick()
  physobjs.children.forEach (child) ->
    physobjdraw child
  renderer.render( stage )
  requestAnimFrame animate
requestAnimFrame animate

root = exports ? this

