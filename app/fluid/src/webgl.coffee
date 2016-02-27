Stats = require('../external/Stats')

class Program
  constructor: (name, globals)->
    @name = name
    @attributes = {}
    @uniforms = {}
    @uniformsAssigned = []
    textureUnit = 0
    for line in globals
      words = line.split ' '
      last = words[words.length - 1]
      ident = last[0..last.length - 2]
      if words[0] == 'attribute'
        @attributes[ident] = gl.getAttribLocation @name, ident
      if words[0] == 'uniform'
        @uniforms[ident] = {}
        loc = gl.getUniformLocation @name, ident
        type = words[words.length - 2]
        @uniforms[ident].loc = loc
        @uniforms[ident].type = type
        if type == 'sampler2D'
          @uniforms[ident].textureUnit = textureUnit
          textureUnit += 1
    @enableAttributes()

  enableAttributes: =>
    for attrib of @attributes
      gl.enableVertexAttribArray @attributes[attrib]

  use: =>
    gl.useProgram @name
    return this

  setUniforms: (uniforms)=>
    for ident of uniforms
      if ident not of @uniforms
        console.log @uniforms
        throw "Undefined Uniform Variable " + ident
      loc = @uniforms[ident].loc
      type = @uniforms[ident].type
      unit = @uniforms[ident].textureUnit
      val = uniforms[ident]
      if type == 'vec2'
        gl.uniform2fv loc, val
      else if type == 'vec4'
        gl.uniform4fv loc, val
      else if type == 'int'
        gl.uniform1i loc, val
      else if type == 'float'
        gl.uniform1f loc, val
      else if type == 'sampler2D'
        if val instanceof Array
          [val, filtering] = val
        if val instanceof DoubleFramebuffer
          val = val.source
        if val instanceof Framebuffer
          val = val.texture
        if val not instanceof Texture
          throw "Sampler2D is not set to Texture!"
        val.bindTo unit
        if filtering
          val.setFiltering(filtering)
        gl.uniform1i loc, unit
      else
        throw "Unrecognized type " + type
      @uniformsAssigned.push ident
    this

  setUp: (parameters)=>
    @use()
    if parameters.uniforms
      @setUniforms parameters.uniforms
    if parameters.vertexData
      if parameters.vertexData == 'quad'
        gpu.bindQuadArrays(this)
        @vertexData = 'quad'
      else
        throw 'Unrecognized VertexData' + parameters.vertexData
    if parameters.target
      @target = parameters.target

    this

  checkUniformAssignments: =>
    for uniform of @uniforms
      if uniform not in @uniformsAssigned
        console.log 'Uniform ' + uniform + ' not Assigned!'

  draw: (parameters)=>
    if parameters
      @setUp parameters

    @checkUniformAssignments()

    if @clear
      @target.getTargetFB.clear()
    if @vertexData == 'quad'
      if @target instanceof DoubleFramebuffer
        @target.drawQuadToTargetAndSwap()
      else if @target instanceof Framebuffer
        @target.bindFB()
        gpu.drawQuad()
    else
      throw "Unrecognized VertexData"
    uniformsAssigned = {}

class Texture
  constructor: (width, height, channels)->
    name = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, name)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    if channels == 4
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.FLOAT, null)
    else if channels == 1
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    gl.bindTexture(gl.TEXTURE_2D, null)
    @name = name
    @width = width
    @height = height

  setNearest: =>
    @setFiltering(gl.NEAREST)

  setLinear: =>
    @setFiltering(gl.LINEAR)

  setFiltering: (filtering)=>
    gl.bindTexture(gl.TEXTURE_2D, @name)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filtering)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filtering)

  bindTo: (unit)=>
    gl.activeTexture(gl.TEXTURE0 + unit)
    gl.bindTexture(gl.TEXTURE_2D, @name)

class Framebuffer
  constructor: (width, height, channels=4)->
    @methods = []
    @width = width
    @height = height
    framebuffer = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
    framebuffer.width = width
    framebuffer.height = height

    texture = new Texture(width, height, channels)

    renderbuffer = gl.createRenderbuffer()
    gl.bindRenderbuffer(gl.RENDERBUFFER, renderbuffer)
    gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, framebuffer.width, framebuffer.height)

    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture.name, 0)
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuffer)

    gl.bindRenderbuffer(gl.RENDERBUFFER, null)
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)

    @name = framebuffer
    @texture = texture

  bindFB: =>
    gl.bindFramebuffer gl.FRAMEBUFFER, @name
    gl.viewport 0, 0, @width, @height
    this

  clear: (color=[0, 0, 0, 0])=>
    gl.clearColor color[0], color[1], color[2], color[3]
    gl.clear(gl.COLOR_BUFFER_BIT)
    this

  fill: (color)=>
    gpu.programs.fill.draw
      uniforms:
        color: color
      vertexData: 'quad'
      target: this

  getTargetFB: =>
    this

class CanvasFB extends Framebuffer
  constructor: ->
    @width = canvas.width
    @height = canvas.height

  bindFB: =>
    gl.bindFramebuffer gl.FRAMEBUFFER, null
    gl.viewport 0, 0, @width, @height
    this

class DoubleFramebuffer
  constructor: ->
    @framebuffers = []

    args = [null]
    for arg in arguments
      args.push arg

    for i in [0..1]
      fb = new (Function.prototype.bind.apply Framebuffer, args)
      @framebuffers.push fb
    @pointer = 0
    @swap()

  swap: =>
    @pointer ^= 1
    @source = @framebuffers[@pointer]
    @target = @framebuffers[@pointer ^ 1]

  drawQuadToTargetAndSwap: =>
    @target.bindFB()
    gpu.drawQuad()
    @swap()

  getTargetFB: =>
    @target

class GPU
  initialize: (programNames)->
    window.canvas = document.getElementById 'main-canvas'
    gl = canvas.getContext 'experimental-webgl'
    gl.disable gl.BLEND
    gl.disable gl.DEPTH_TEST
    if not gl.getExtension('OES_texture_float')
      alert "Error: no float texture support!"
    if not gl.getExtension('OES_texture_float_linear')
      alert "Error: no float texture lerp support!"
    for ext in gl.getSupportedExtensions()
      gl.getExtension ext
    window.gl = gl
    @initializeQuadVBOs()
    @programNames = programNames.concat ['plot', 'fill']
    @programs = []
    @loadAllPrograms()
    window.canvasFb = new CanvasFB()
    stats = new Stats()
    stats.setMode(1);
    stats.domElement.style.position = 'absolute';
    stats.domElement.style.left = '0px';
    stats.domElement.style.top = '0px';
    document.body.appendChild( stats.domElement );
    @timeingStats = stats
    stats = new Stats()
    stats.setMode(0);
    stats.domElement.style.position = 'absolute';
    stats.domElement.style.left = '80px';
    stats.domElement.style.top = '0px';
    document.body.appendChild( stats.domElement );
    @fpsStats = stats

  bindQuadArrays: (prog)->
    gl.bindBuffer(gl.ARRAY_BUFFER, gpu.quadVertexPosbuffer)
    gl.vertexAttribPointer(prog.attributes.position, gpu.quadVertexPosbuffer.itemSize, gl.FLOAT, false, 0, 0)
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, gpu.quadVertexIndbuffer)

  drawQuad: ->
    gl.drawElements(gl.TRIANGLES, gpu.quadVertexIndbuffer.numItems, gl.UNSIGNED_SHORT, 0)

  parseProgram: (code)->
    lines = code.split '\n'
    globals = []
    for line, i in lines
      line = line.trim()
      if line.startsWith("//***")
        line = line.substring(5, line.length - 3)
        line = line.trim().toLowerCase()
        if line == "globals"
          globalStart = i
        if line == "vertex shader"
          vsStart = i
        if line == "fragment shader"
          fsStart = i

    globals = lines.slice(0, vsStart)
    nonAttributes = globals.filter (line)->
      !line.startsWith 'attribute'
    vertexShaderLines = globals.concat(lines.slice(vsStart, fsStart))
    fragmentShaderLines = nonAttributes.concat lines.slice(fsStart, lines.length)
    fragmentShaderLines = ['precision highp float;\nprecision highp int;'].concat fragmentShaderLines

    vertexShader = vertexShaderLines.join '\n'
    fragmentShader = fragmentShaderLines.join '\n'

    [globals, vertexShader, fragmentShader]

  initializeQuadVBOs: ()->
    quadVertexPosbuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexPosbuffer)
    vtxPos = [
      -1.0, -1.0,
      1.0, -1.0,
      1.0, 1.0,
      -1.0, 1.0,
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vtxPos), gl.STATIC_DRAW)
    quadVertexPosbuffer.itemSize = 2
    quadVertexPosbuffer.numItems = 4

    quadVertexIndbuffer = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, quadVertexIndbuffer)
    vtxInd = [0, 1, 2, 0, 2, 3]
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(vtxInd), gl.STATIC_DRAW)
    quadVertexIndbuffer.itemSize = 1
    quadVertexIndbuffer.numItems = 6
    @quadVertexPosbuffer = quadVertexPosbuffer
    @quadVertexIndbuffer = quadVertexIndbuffer

  plotTexture: (texture, offset=[0, 0], log)->
    gpu.programs.plot.draw
      uniforms:
        bufSize: [texture.width, texture.height]
        screenSize: [canvasFb.width, canvasFb.height]
        texture: [texture, gl.NEAREST]
        offset: offset
        transform: log
      vertexData: 'quad'
      target: canvasFb
      clear: true

  constructor: ->
    @textures = []
    @programs = []

  createTexture: (width, height)->

  createGlobal: (name)->

  getShader: (type, code)->
    shader = gl.createShader type, code

    gl.shaderSource shader, code
    gl.compileShader shader
    log = gl.getShaderInfoLog(shader)
    if log
      console.log code
      console.log log
      throw "Shader Error"
    shader

  createProgram: (vs, fs)->
    prog = gl.createProgram()
    gl.attachShader(prog, @getShader(gl.VERTEX_SHADER, vs))
    gl.attachShader(prog, @getShader(gl.FRAGMENT_SHADER, fs))
    gl.linkProgram prog
    log = gl.getProgramInfoLog(prog)
    if log
      console.log log
    prog

  loadProgram: (name)=>
    msg = require('../shaders/' + name + '.glsl')
    [globals, vs, fs] = @parseProgram msg
    @programs[name] = new Program (@createProgram vs, fs), globals

  loadAllPrograms: ->
    @numProgramsLeft = @programNames.length
    for programName in @programNames
      @loadProgram programName

  onStart: (func)=>
    @onStartFunc = func

  start: ()=>
    console.log 'GL Loaded'
    @onStartFunc()

  bindCanvas: =>
    gl.bindFramebuffer gl.FRAMEBUFFER, null
    gl.viewport 0, 0, canvas.width, canvas.height

window.Program = Program
window.Texture = Texture
window.Framebuffer = Framebuffer
window.DoubleFramebuffer = DoubleFramebuffer
window.GPU = GPU
