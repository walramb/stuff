# Quad tree based AABB collisions

#rectangle format is a simple 4 key object
rect = (x,y,w,h) ->
  return x:x, y:y, w:w, h:h

class QuadTree
  constructor: (@level=0,@bounds) ->
    @bounds ?= x: 0, y: 0, w: 640, h: 480
    @MAXOBJS = 1
    @MAXDEPTH = 4
    @objs = []
    @subnodes = []
  clear: ->
    @objs = []
    @subnodes = []

QuadTree::split = ->
  x = @bounds.x
  y = @bounds.y
  w = Math.floor @bounds.w/2
  h = Math.floor @bounds.h/2
  @subnodes[0]=new QuadTree @level+1, rect x+w,y,w,h
  @subnodes[1]=new QuadTree @level+1, rect x,y,w,h
  @subnodes[2]=new QuadTree @level+1, rect x,y+h,w,h
  @subnodes[3]=new QuadTree @level+1, rect x+w,y+h,w,h

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

QuadTree::insert = ( newobj ) ->
  if @subnodes.length > 0
    index = @getindex newobj
    if index isnt -1
      @subnodes[index].insert newobj
  @objs.push newobj
  if @objs.length > @MAXOBJS and @level < @MAXDEPTH
    if @subnodes.length == 0
      @split()
      @objs.forEach (obj) =>
        index=@getindex obj
        if index isnt -1
          @subnodes[index].insert obj
          @objs = _.without @objs, obj

QuadTree::retrieve = ( rect ) ->
  retobjs = []
  index = @getindex rect
  if index isnt -1 and @subnodes.length isnt 0
    retobjs = @subnodes[index].retrieve retobjs, rect
  retobjs = _.union retobjs, @objs
  return retobjs

root = exports ? this
root.QuadTree = QuadTree

