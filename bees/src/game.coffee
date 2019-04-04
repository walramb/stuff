# = video game engine
# "bees" branch

# a project by a walrus
# 2016

# dependencies: (??? todo: weed out jquery probably)
# * jQuery
# * Underscore.js
# * pixi.js

# homebrew libraries:
# * helpers.js
# * morehelpers.js
Rect = halp.Rect

#this is to contain everything ever
jame = {}

#paths
THISFILE = "js/game.js"
sourcebaseurl = "./sprites/"
audiobaseurl="./audio/"
imgext = ".png"

settings =
  fps : 30
  muted : false
  paused : false
  volume : 3/8
  scale : 1
jame.settings = settings

ls =
data: {}
save: ->
  localStorage.setItem 'beegame', JSON.stringify @data
  console.log 'saved localstorage'
load: ->
  @data = JSON.parse localStorage.getItem 'beegame'
  @data ?= {}
  console.log 'loaded localstorage'
  console.log @data

ls.load()
settings.muted = ls.data.muted or false

# MVP helper/syntax sugar coming through
# we're going to be using this a hella lot
V = (x=0,y=0) -> new V2d x,y

# some more settings relating to video mode
screensize = V 960, 540 # halved 1080p
playingfield = new Rect 0, 0, 360, 480

###
= "helper" functions
for readability or whatever
###

#using CAPS to make some things stand out as red in my highlighted syntax
LOG = (text) -> console.log text

#linear interpolation
#misnamed??
linterpolate = (a,b,frac) -> a+(b-a)*frac

#interval in ms -> a per-second frequency
hz = (ms) -> Math.round 1000/ms

makebox = (position, dimensions, anchor) ->
  truepos = position.vsub dimensions.vmul anchor
  new Rect truepos.x, truepos.y, dimensions.x, dimensions.y

###
deepExtend pilfered from Ryan LeFevre

this is intended as a fairly generic way to
alter default values of new objects,
in a more data-driven way.

(instead of dealing with unnamed arguments or lots of method calls
or whatever.)
deep so you can alter a component of an object such as coordinates
without completely overwriting the whole object.

I imagine something more like this:
  ent = new Entity pos: {x:0, y:0}, vel: {x: 0, y:32}
###
deepExtend = (object, extenders...) ->
  return {} if not object?
  for other in extenders
    for own key, val of other
      if not object[key]? or typeof val isnt "object"
        object[key] = val
      else
        object[key] = deepExtend object[key], val
  object


noop = ->

# help locating sprites
imgpath = (basename) -> sourcebaseurl+basename+imgext

_TEXBYNAME = (imgsrc) ->
  LOG imgpath imgsrc
  PIXI.Texture.fromImage imgpath imgsrc


_blat = (text,offs=0) ->
  ent=new Renderable()
  ent.anchor = V 0,0
  ent.pos.y += 32 * offs
  textcontainer = maketext text
  ent._pixisprite = textcontainer
  WORLD.entAdd ent
  return ent

_SPRITE = (tex) -> new PIXI.Sprite tex

# some wrapper funcs to deal with Pixi's version of points/vectors
PP = (x,y) -> new PIXI.Point x,y
VTOPP = (v) -> PP v.x, v.y

# clamp_posiition. it clamps a position.
# returns a new pos that is within rectangle bounds
clamp_position = ( pos=V(), rect=new Rect() ) ->
  x=mafs.clamp pos.x, rect.left(), rect.right()
  y=mafs.clamp pos.y, rect.top(), rect.bottom()
  V x,y

#

preload = (src) -> PIXI.loader.add(imgpath src).load()

XXXX = (tilesrc, tileW, tileH, cols, rows) ->
  preload tilesrc
  pxSheetW=tileW*cols
  pxSheetH=tileH*rows
  _tileset = _TEXBYNAME tilesrc
  _tileset.baseTexture.width = pxSheetW
  _tileset.baseTexture.height = pxSheetH
  tsw = 20 #tileset width in tiles
  tilesize = 16
  rowcount = 8
  numtiles = rows*cols
  return _maketiles _tileset, tileW, tileH, cols, rows

gettileoffs = (n,tsw, tilesize) ->
  V n%tsw, Math.floor n/tsw

# slice an image into square textures
# texture -> array of square texture slices
maketiles = (tileset, tsize, cols, rows) ->
  #rows=numtiles/cols
  _maketiles tileset, tsize, tsize, cols, rows

_maketiles = (tileset, tileW, tileH, cols, rows ) ->
  numtiles=cols*rows
  range=[0...numtiles]
  texs= for i in range
    tex = new PIXI.Texture tileset
    {x,y}=gettileoffs i, cols
    rec = new PIXI.Rectangle x*tileW, y*tileH, tileW, tileH
    tex.frame = rec
    tex


fontsrc = "font-hand-white-12x16"
fonttexs = XXXX fontsrc, 12, 16, 16, 6

body = $ "body"

playsound = ( src ) ->
  return if settings.muted
  snd = new Audio()
  snd.src = audiobaseurl+src
  snd.volume = settings.volume
  snd.play()

field = playingfield
renderer = new PIXI.CanvasRenderer screensize.x, screensize.y
stage = new PIXI.Graphics()

_decorate = (stage) ->
  stage.beginFill 0x001122
  stage.drawRect field.x, field.y, field.w, field.h
  stage.endFill()

#from Space to Tilde
ascii = String.fromCharCode.apply @, [32..126]
fontmap=ascii

# jiggle each letter individually
_charspritetick = (sp) ->
  tickno=WORLD.tickno
  sp.anchor.y = 1-Math.sin(sp.varn+tickno/2)/8
  sp.anchor.x = 1/2
  scale = 1+Math.max 0, Math.sin(sp.varn/8-tickno/12)
  sp.scale.x = sp.scale.y = scale
  return

maketext = (txt) ->
  charwidth = 16
  offs = V 64, 128
  chars = txt.split ""
  itxt = chars.map (x) -> fontmap.indexOf x
  spaces = 0
  sprites = ( for n,i in itxt
    if n is 0 then spaces++
    sp=_SPRITE fonttexs[n]
    sp.varn = i + spaces*64
    sp.position = VTOPP offs.vadd V i*charwidth,0
    sp
  )
  tck = new PIXI.ticker.Ticker()
  tck.autoStart = true
  tck.add -> sprites.forEach _charspritetick
  textcontainer = new PIXI.Graphics()
  textcontainer.addChild sp for sp in sprites
  return textcontainer


body.append renderer.view

# handle key bindings
class ControlObj
  constructor: ->
    @bindings={}
    @holdbindings={}
    @heldkeys=[]
    @bindingnames={}
    @reservedkeys=[]
  isHolding: (keyname) -> keyCharToCode[keyname] in @heldkeys
  bind: ( argkey, name, func=noop ) ->
    key=keyCharToCode[argkey]
    @bindingnames[key]=name
    @bindings[key]=func
  reserve: (keyname) ->
    @reservedkeys.push keyCharToCode[keyname]

control = new ControlObj
jame.control = control

control.bind 'R', 'reset stage', ->
  WORLD.reset()
control.bind 'W', 'win', ->
  WORLD.WIN()


control.bind 'G', 'show hitboxes', ->
  WORLD.entAdd new HitboxSprite
control.bind 'T', 'do tick', ->
  settings.paused = true
  do WORLD.tick
control.bind 'Enter', 'pause', ->
  if not settings.paused
    WORLD.pause()
control.bind 'Esc', 'toggle pause', ->
  WORLD.pause()

# which keys to prevent browser from handling normally
# don't want to be scrolling around when trying to play
control.reserve key for key in \
[ "Space", "Up", "Down", "Backspace", "Left", "Right" ]

# doing the actual DOM keylistener binding
eventelement = $ document

eventelement.bind 'keydown', (e) ->
  key = e.which
  control.bindings[key]?()
  unless key in control.heldkeys
    control.heldkeys.push key
  not (key in control.reservedkeys)

eventelement.bind 'keyup', (e) ->
  key = e.which
  control.heldkeys = _.without control.heldkeys, key
  not (key in control.reservedkeys)

#

camera =
  offset: V()
  pos: V()
  tick: ->

class World
  constructor: ->
    @entities=[]
    @tickno=0
    @camera=camera
  entAdd: (ent) ->
    @entities.push ent
    ent.render?()
    stage.addChild ent._pixisprite
  entRemove: (ent) ->
    @entities = _.difference @entities, [ent]
    stage.removeChild ent._pixisprite
    ent._cleanup?()

WORLD = new World

World::render = ->
  @camera.tick()
  renderables = @entities
  renderables.forEach (ent) -> ent.render?()
World::tick = ->
  @tickno++
  for key in control.heldkeys
    control.holdbindings[key]?() #TODO wee woo global
  @collect_hitboxes()
  hitboxcollection.tick()
  #using "try" to experiment with entities at runtime
  #without stalling the whole thing
  @entities.forEach (ent) -> try ent.tick?()
  @render()


hitboxcollection = new class HitBoxCollection
  constructor: ->
    @clear()
  getcolls: (ent) ->
    res=_.filter @collpairs, (pair) -> pair[0] is ent
    return res
  add: (ent) ->
    return if not ent.genhitbox
    newbox = ent.genhitbox()
    for box,i in @boxcache #O complexity too high
      if newbox.overlaps box
        @collpairs.push [ent, @cache[i]]
        @collpairs.push [@cache[i], ent]
    @cache.push ent
    @boxcache.push ent.genhitbox()
  tick: () ->
    for [fst,scd] in @collpairs
      fst.coll?(scd)
      #scd.coll?(fst)
      #oop it counts each coll twice with the second one
  clear: ->
    @cache = []
    @boxcache = []
    @collpairs = []

World::collect_hitboxes = ->
  hitboxcollection.clear()
  for ent in @entities
    hitboxcollection.add ent

class Renderable
  constructor: ->
    @pos = V()
  render: ->
    @_pixisprite ?= _SPRITE _TEXBYNAME @sprite
    @_pixisprite.position = VTOPP @pos
    @_pixisprite.anchor = VTOPP @anchor
    @render_?() #define a unique method for each entity, instead of calling super

class Entity extends Renderable
  constructor: (argobj) ->
    super()
    @vel = V()
    @timers={}
    @init?()
    @anchor = V 1/2, 1/2
    deepExtend @, argobj
Entity::_cleanup = ->
  stage.removeChild @_pixisprite

class HitboxSprite extends Entity
  render: ->
    @_pixisprite ?= new PIXI.Graphics()
    sp=@_pixisprite
    sp.clear()
    WORLD.entities.forEach (ent) ->
      return if not ent.genhitbox
      box=ent.genhitbox()
      sp.lineStyle 1, 0x00FF00
      sp.drawRect box.x, box.y, box.w, box.h
      sp.lineStyle 1, 0xFF00FF
      sp.drawCircle ent.pos.x, ent.pos.y, 2

Entity::size = V 16, 16
Entity::genhitbox = ->
  makebox @pos, @size, @anchor
Entity::timeoutcheck = -> #rename to timerhandler or something?
  for k,v of @timers
    if v>0 then @timers[k]--
Entity::kill = ->
  WORLD.entRemove @

Entity::physmove = ->
  @pos=@pos.vadd @vel

#sprite related, move into "sprite" subobject?
Entity::flipsprite = ->
  if @vel.x isnt 0
    targ = -Math.sign @vel.x
    actual = @_pixisprite.scale.x
    @_pixisprite.scale.x = linterpolate actual, targ, 1/4

# spawn a new ent at this ent's location
# (rename?? sounds ambiguous.  move to World?)
Entity::spawn = (proto) ->
  ent = new proto pos: @pos
  WORLD.entAdd ent
  return ent

Entity::clampposition = ( rect ) ->
  @pos = clamp_position @pos, rect


# bzz
preload "beesplode"
class InvaderBee extends Entity
InvaderBee::init = ->
  @sprite = "bee"
  @vel = V 2, 0
  @targetpos = @pos
  @deathanim = new Animation parent: this, texname: "beesplode", tilesize: 64, framecount: 4
  @anim = new Animation parent: this, texname: "bee", tilesize: 32, framecount: 1
  @state = new StateMachine @
  @state.set "normal"
  @resettimer()
InvaderBee::dropRate = 1/6
InvaderBee::resettimer = ->
  @timers.shoot = 32+32*mafs.randint 32
InvaderBee::_tick = -> #no matter which state
  @physmove()
  if @isoffscreen()
    @vel=@vel.nmul -1.05
    @targetpos.y += 16
  @_tween()
  @clampposition playingfield
InvaderBee::tick = ->
  @timeoutcheck()
  @state.tick()
  @_tick()

InvaderBee::tickfuns =
dying: ->
  if @state.tickno > 0
    @targetpos.y -= 2
    @vel.x = 0
  if @state.tickno > 12
    WORLD.entRemove @
    WORLD.stats.hits++
    console.log WORLD.stats.hits
normal: ->
  @_sway()
  @shootthebullet()

InvaderBee::_tween = ->
  @pos.y = linterpolate @pos.y, @targetpos.y, 1/3

#returns a bool
InvaderBee::isoffscreen = ->
  @pos.x > playingfield.right() or @pos.x < playingfield.left()

InvaderBee::_sway = ->
  @anchor.y = 1/2+Math.sin(WORLD.tickno/6)/16

InvaderBee::_shoot = (velocity) ->
  if Math.random() < 1/6
    ent=@spawn BadSuperBullet
  else
    ent=@spawn BadBullet
    ent.vel = velocity

InvaderBee::shootthebullet = (num) ->
  return if @timers.shoot
  @resettimer 'shoot'
  @_shoot V 0,4
  playsound "jump.wav"

InvaderBee::kill = ->
  playsound "hit.wav"
  playsound "boip.wav"
  @anim = @deathanim
  @state.set "dying"
  if Math.random() <= @dropRate
    @spawn PowerUp

InvaderBee::render_ = ->
  @flipsprite()
  @texset @anim.tex()
  if @timers.shoot < 8
    @texset @deathanim.tileset[0]

#TODO MOVE
WORLD.WIN = ->
  return if WORLD.winstate
  WORLD.winstate = true
  _blat "WOW! u done it."
  _blat "#{WORLD.stats.shots} sparkles fired", 2
  acc=Math.round WORLD.stats.hits/WORLD.stats.shots*100
  _blat "#{acc}% accuracy", 3
  _blat "cleared in #{Math.round WORLD.tickno/settings.fps} seconds", 4
  _blat "rip #{WORLD.stats.hits} bees", 5

class Physobj
  constructor: ->
    @pos ?= V()
    @vel ?= V()
    @fric ?= V() #friction or dampening
    @acc ?= V()

#rename to a verb?
Entity::phystick = ->
  @pos = @pos.vadd @vel
  @vel = @vel.vadd @acc
  @vel = @vel.vmul @fric
Entity::physinit = ->
  @pos ?= V()
  @vel ?= V()
  @fric ?= V() #friction or dampening
  @acc ?= V()


#a state machine can only be in one state at a time
#parent is an Entity
class StateMachine
  constructor: ( @parent ) ->
    @tickno = 0
    @state = "idle"
  tick: ->
    @tickno++
    @parent.tickfuns[@get()]?.apply @parent
  get: -> @state
  set: (statename) ->
    @state = statename
    @tickno = 0
  setif: (statename, cond) ->
    if cond then @set statename

class PlayerFairy extends Entity
  init: ->
    @sprite = "emily"
    @targetpos = V(0,320)
    @vel=V()
    @state = new StateMachine @
    @state.set "normal"
    @shootmode = 1
    @hp=3
    #physics
    @acc = V 0, 0 #acceleration
    @fric = V 0.5, 1 #friction
    @timers.mana = 0
  tiles: maketiles _TEXBYNAME("emilysheet"), 32, 2, 3
  tick: ->
    @state.tick()
    @flipsprite()
  plyinput: ->
    @acc.x = 0
    if control.isHolding "Left"
      @acc.x = -6
    if control.isHolding "Right"
      @acc.x = +6
    if not @timers.vertical
      if control.isHolding "Up"
        @targetpos = V 0,320-48
        @timers.vertical=10
      if control.isHolding "Down"
        @targetpos = V 0,320
        @timers.vertical=10
    if control.isHolding "X"
      @shootthebullet @shootmode

PlayerFairy::hit = ->
  playsound "hit.wav"
  playsound "but.wav"
  state = @state.get()
  return if state is "dead" or state is "hurt"
  @state.set "hurt"
  @hp--

PlayerFairy::powerup = (shootmode) ->
  @shootmode = shootmode

#sprite flashing
PlayerFairy::_blink = ->
  @_pixisprite.alpha = 1-@state.tickno % 2

#nudge towards @targetpos
PlayerFairy::_tween = ->
  @pos.y = linterpolate @pos.y, @targetpos.y, 1/2

PlayerFairy::_sway = ->
  @anchor.y = 1/2 + Math.sin(WORLD.tickno/3)/16

PlayerFairy::tickfuns =
dead: ->
  if @state.tickno is 1
    @vel.y = -15
  @vel.x = 0
  @acc.y = 2
  if @vel.y > 0
    @texset @tiles[4]
  @phystick()
  if @pos.y > 600 #when offscreen
    @_gameover()
    @state.set "normal"
    @init()

hurt: ->
  @plyinput()
  @state.setif "dead", @hp <= 0
  if @state.tickno >= 15
    @state.set "normal"
  if @state.tickno <= 10
    @targetpos.y = 320+16
  @texset @tiles[2]
  @_tween()
  @_blink()

normal: ->
  #@targetpos.y = 320
  @texset @tiles[0]
  @plyinput()
  @phystick()
  @_sway()
  @_tween()
  @timeoutcheck()
  @clampposition playingfield
  bees = WORLD.entities.filter (ent) -> ent instanceof InvaderBee
  if bees.length <= 0
    WORLD.WIN()

PlayerFairy::_gameover=->
  @kill()
  _blat "GAME OVER"
  txtcont = _blat "[R] to restart"
  txtcont.pos.y += 64

PlayerFairy::coll = (ent) ->
  die_on = [ BadBullet, InvaderBee ]
  for proto in die_on
    if ent instanceof proto
      @hit()

#this is supposed to be in coffeescript as double slashes
# but apparently is not?? maybe im using wrong version
intdiv = (n,d) -> Math.floor n/d
intdivmod = (n,d,m) -> intdiv(n/d)%m


_selectframe = ( framelist, framewait ) ->
  totalframes = framelist.length
  framechoice = intdiv(WORLD.tickno,framewait)%totalframes
  framelist[framechoice]


projectiles = maketiles _TEXBYNAME("projectiles"), 16, 5, 3
sparkletiles = projectiles[1..4]
pollentiles = maketiles _TEXBYNAME("pollen"), 16, 4, 1


class Timer
  constructor: (@initialvalue = 0) ->
    @reset()
  set: (@count) ->
  get: -> @count
  tick: ->
    if @count > 0
      @count--
  reset: ->
    @count = @initialvalue

class Animation
  constructor: (argobj) ->
    deepExtend @, argobj
    @tilesize ?= 16
    @texname ?= "sparkleshot"
    @framecount ?= 5
    @tileset ?= maketiles _TEXBYNAME(@texname), @tilesize, @framecount, 1
    @tickno = 0
    @framedelay ?= 4 #ticks between frames \ frame length in ticks
    @frameoffset ?= 0 #number of first frame to use
  tex: ->
    @tickno = @parent?.state?.tickno or WORLD.tickno
    currframe = Math.floor( @tickno / @framedelay )
    currframe = @frameoffset + currframe % @framecount
    return @tileset[currframe]

Renderable::texset = (tex) ->
  @_pixisprite.texture = tex

floweranim = new Animation texname: "flowert"
#presets of frame sequences
floweranim.presets=
  block:
    frameoffset: 0
    framecount: 4
  spin:
    frameoffset: 4
    framecount: 1
floweranim.setseq = (name) ->
  deepExtend @, @presets[name]

class Barrier extends Entity
  size: V 16,16
  anim: floweranim
  tick: ->
    @timeoutcheck()
  render_: ->
    if @timers.coll
      @anim.setseq "spin"
    else
      @anim.setseq "block"
    @texset @anim.tex()

Barrier::coll = (ent) ->
  super(ent)
  if ent instanceof BadBullet
    playsound "pause.wav"
    @timers.coll = 16
  if ent instanceof BadSuperBullet
    @kill()

#DEFAULT ENTITY COLLISION HANDLER

Entity::die_on = []
Entity::coll = (ent) ->
  #die if colliding with any types enumerated in @die_on
  for proto in @die_on
    if ent instanceof proto
      @kill()

class Bulletproto extends Entity
  size: V 8, 8
  isoffscreen: ->
    @pos.y < 0 or @pos.y > 360
  tick: ->
    @_pixisprite.texture = _selectframe @tiles, 2
    @physmove()
    if @isoffscreen()
      @kill()

class Bullet extends Bulletproto
  init: ->
    @anim=new Animation tileset: projectiles, framecount: 4, framedelay: 1
    @tiles=sparkletiles
  render_: ->
    @anim.frameoffset = 1+(@shootmode-1) * 5
    @texset @anim.tex()

class BadBullet extends Bulletproto
  init: ->
    @tiles = pollentiles
class BadSuperBullet extends BadBullet
  init: ->
    @vel = V 0, 2
    @tiles = sparkletiles

BadBullet::die_on = [ PlayerFairy, Barrier, Bullet ]
Bullet::die_on = [ InvaderBee, Barrier, BadBullet ]

Barrier::die_on = [ Bullet ]
InvaderBee::die_on = [ Bullet, PlayerFairy ]

class PowerUp extends Entity
  size: V 8, 8
  init: ->
    @vel= V 0, 2
    @shootmode = 1+mafs.randint 3
  sprite: "sparkleshot"
  tick: ->
    @physmove()
    if @isoffscreen()
      @kill()
  coll: (ent) ->
    if ent instanceof PlayerFairy
      @kill()
      ent.powerup @shootmode
      ent.timers.mana-=128
  render_: ->
    offs=(@shootmode-1)*5
    projectiles = maketiles _TEXBYNAME("projectiles"), 16, 5, 3
    @texset projectiles[offs]

class Hud extends Entity
  sprite: "sparkleshot"
  init: ->
    @pos = V 64,360
  render: ->
    mana = WORLD.playerent.timers.mana
    maxmana = 1100
    @anchor = V 0,0
    @_pixisprite ?= new PIXI.extras.TilingSprite _TEXBYNAME @sprite
    deepExtend @_pixisprite,
      pivot: VTOPP V 0,0
      width: (maxmana-mana)/4
      height: 16
      tilePosition: x: WORLD.tickno/8
    super()

PlayerFairy::shootthebullet = (num) ->
  shotpattern = [V(0,-8), V(2,-7), V(-2,-7)]
  return if @timers.shoot or (@timers.mana > 1000)
  playsound "boip.wav"
  @timers.mana += 64
  WORLD.stats.shots+=num
  _shoot = (vel,offs=V()) =>
    WORLD.entAdd new Bullet pos: @pos.vadd(offs), vel: vel, shootmode: @shootmode
  if num is 1
    _shoot V @vel.x/2,-10
    @timers.shoot = 8
  if num is 2
    _shoot V(0,-6), V -8
    _shoot V(0,-6), V 8
    @timers.shoot = 16
  if num is 3
    _shoot vel for vel in shotpattern
    @timers.shoot = 16
  return

do animate = ->
  renderer.render(stage)
  requestAnimationFrame animate

WORLD.mainloop = ->
  if not settings.paused
    do WORLD.tick
  else
    do pausePlane.tick
  setTimeout WORLD.mainloop, hz settings.fps

World::reset = ->
  @entities = []
  stage = new PIXI.Graphics()
  _decorate stage
  @init()

# hardcoded level design
WORLD.titleinit = ->
  _decorate stage
  _blat "a game what contains some bees"
  x=_blat "press R to play"
  x.pos.y += 128
  flowerline()

flowerline = ->
  [0..4].forEach (i) ->
    WORLD.entAdd new Barrier pos: V 32+i*16, 300
    WORLD.entAdd new Barrier pos: V 32*5+i*16, 300
    WORLD.entAdd new Barrier pos: V 32*9+i*16, 300
beeline = ->
  [0...32].forEach (i) ->
    b = new InvaderBee
    b.pos.x = 32*(i%8)
    b.pos.y = Math.floor(i/8)*32
    WORLD.entAdd b

WORLD.init = ->
  @tickno=0
  flowerline()
  beeline()
  em = new PlayerFairy
  em.pos = V 64, 320
  WORLD.entAdd em
  WORLD.playerent = em
  WORLD.entAdd new Hud
  @winstate = false
  WORLD.stats = shots: 0, hits: 0


#

PIXI.loader.load ->
  do WORLD.titleinit
  WORLD.mainloop()

#DOM garbage goes here

$(renderer.view).contextmenu -> false

###
exports
###
root = exports ? this

jame.WORLD = WORLD

root.jame = jame
root.stage = stage


#MENU
class SelectIndicator extends Renderable

  constructor: (menu) ->
    super()
    @menu=(v for k,v of menu)
    @option=0
    @numoptions=@menu.length
    @anchor = V 0,0
    @_pixisprite = maketext "->"
    @pos.x -= 40
    @targetpos = V 0,0
    @timers = menudelay: new Timer 6

  checkcontrols: ->
    tap = (key) =>
      cond=jame.control.isHolding key
      if cond then @timers.menudelay.reset()
      return cond
    if not @timers.menudelay.get()
      if tap 'Up'   then @option--
      if tap 'Down' then @option++
      if tap 'Right'
        @menu[@option] +1
        pausePlane.update()
      if tap 'Left'
        @menu[@option] -1
        pausePlane.update()
      if tap 'Enter'
        do @menu[@option]

  tick: ->
    @timers.menudelay.tick()
    @checkcontrols()
    @option=mafs.mod @option, @numoptions
    @targetpos.y = 32+ @option * 32
    @pos.y = linterpolate @pos.y, @targetpos.y, 1/2

sanitize_settings = ->
  settings.volume = mafs.clamp settings.volume, 0, 1

menu =
"return": (i) ->
  return if i > -2
  WORLD.pause()
"mute": (i) ->
  if i is 0
    return "mute: " + if settings.muted then "yes" else "no"
  settings.muted = not settings.muted
  ls.data.muted = settings.muted
  ls.save()
"volume": (i) -> #HACKWARNING a -1 or +1 argument means L/R arrows were pressed
  if i is 0
    return "volume: " + "|".repeat settings.volume * 8
  if i > 0
    settings.volume += 1/8
  if i < 0
    settings.volume -= 1/8
  sanitize_settings()
  console.log settings.volume
  playsound "boip.wav"
"restart": (i) ->
  return if i > -2
  settings.paused = false
  WORLD.reset()

pausePlane = new World
pausePlane.init = ->
  pausePlane.entAdd new SelectIndicator menu
  e = _text "PAUSED"
  e.pos.y = -32
  pausePlane.entAdd e
  @textents=[]
  @update()
pausePlane.update = ->
  num=0
  console.log @
  for e in @textents
    @entRemove e
    console.log "deleted"
  @textents = []
  for k,v of menu
    num++
    text = v(0) or k #functions return their menu label if given 0 as argument
    e = _text text
    e.pos.y = 32*num
    pausePlane.entAdd e
    @textents.push e

pausePlane.reset = ->
  @cleanup()
  @entities = []
pausePlane.cleanup = ->
  @entities.forEach (ent) ->
    stage.removeChild ent._pixisprite
    ent._cleanup?()

WORLD.pause = ->
  settings.paused = !settings.paused
  pausePlane.reset()
  if settings.paused then pausePlane.init()

_text = (text) ->
  ent=new Renderable()
  ent.anchor = V 0,0
  textcontainer = maketext text
  ent._pixisprite = textcontainer
  return ent
