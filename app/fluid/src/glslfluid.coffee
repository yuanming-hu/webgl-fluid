require('../external/Stats')
require('./webgl')

class MAC
  constructor: ->
    console.log "GLSLFluid initialzing"
    window.gpu = new GPU()
    gpu.initialize @getPrograms()
    @initialOffset = [0.25, 0.25]

    @dim = 64
    @gravity = [0, -1]
    @t = 0.0
    @initializeFbs()

    @simulate()
    @initializeMouse()

  initializeMouse: =>
    @mouseStrength = 2.2
    @dragging = false
    @mouseCoord = [0, 0]

    return
    $(canvas).mousedown (e) =>
      @dragging = true
    $(canvas).mouseup (e) =>
      @dragging = false
    $(canvas).mousemove (e) =>
      x = (e.pageX - canvas.offsetLeft) / canvas.width
      y = (canvas.height - (e.pageY - canvas.offsetTop)) / canvas.height
      @mouseCoord = [x, y]

  initializeFbs: =>
    @particleFbs = new DoubleFramebuffer(@dim, @dim)
    @pressureFbs = new DoubleFramebuffer(@dim, @dim)
    @uFbs = new DoubleFramebuffer(@dim + 1, @dim)
    @vFbs = new DoubleFramebuffer(@dim, @dim + 1)
    @cellsFb = new Framebuffer(@dim, @dim)
    @backBuffer = new Framebuffer(canvas.width, canvas.height)
    @systemFb = new Framebuffer(@dim, @dim)
    @poissonSolver = new PoissonSolver(@dim)

  getPrograms: ->
    ['initialize', 'iterate', 'points',
      'markCells', 'buildSystem', 'applyExternalForces',
      'jacobiSolver', 'advect', 'applyBoundaryCondAndMarkValid',
      'extrapolate', 'jacobiSolver', 'applyPressure', 'moveMarkers']

  markCells: ()->
    prog = gpu.programs.markCells.use().setUniforms
      bufSize: [@cellsFb.width, @cellsFb.height]
      texture: @particleFbs

    gl.bindBuffer(gl.ARRAY_BUFFER, @pointIdBuffer)
    gl.vertexAttribPointer(prog.attributes.id, @pointIdBuffer.itemSize, gl.FLOAT, false, 0, 0)

    @cellsFb.bindFB().clear()
    gl.drawArrays(gl.POINTS, 0, @pointIdBuffer.numItems)

  initialize: =>
    numPoints = @dim * @dim
    pointIdBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, pointIdBuffer)
    pointIds = [0..numPoints - 1]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(pointIds), gl.STATIC_DRAW)
    pointIdBuffer.itemSize = 1
    pointIdBuffer.numItems = numPoints
    @pointIdBuffer = pointIdBuffer

    gpu.programs.initialize.draw
      uniforms:
        bufSize: [@dim, @dim]
        offset: @initialOffset
      target: @particleFbs
      vertexData: 'quad'

  renderParticles: ()=>
    prog = gpu.programs.points.use().setUniforms
      texture: @particleFbs
      bufSize: [@dim, @dim]

    gl.bindBuffer(gl.ARRAY_BUFFER, @pointIdBuffer)
    gl.vertexAttribPointer(prog.attributes.id, @pointIdBuffer.itemSize, gl.FLOAT, false, 0, 0)

    @backBuffer.bindFB().clear()
    gl.enable gl.BLEND
    gl.blendFunc gl.SRC_ALPHA, gl.ONE
    gl.drawArrays gl.POINTS, 0, @pointIdBuffer.numItems
    gl.disable gl.BLEND

  buildSystem: ()=>
    gpu.programs.buildSystem.draw
      uniforms:
        bufSize: [@dim, @dim]
        cells: [@cellsFb, gl.LINEAR]
        uTexture: [@uFbs, gl.NEAREST]
        vTexture: [@vFbs, gl.NEAREST]
      vertexData: 'quad'
      target: @systemFb

  moveMarkers: (deltaT)=>
    gpu.programs.moveMarkers.draw
      uniforms:
        bufSize: [@dim, @dim]
        deltaT: deltaT
        uTexture: [@uFbs, gl.LINEAR]
        vTexture: [@vFbs, gl.LINEAR]
        particleTexture: [@particleFbs, gl.NEAREST]
      vertexData: 'quad'
      target: @particleFbs

  applyPressure: ()=>
    gpu.programs.applyPressure.draw
      uniforms:
        bufSize: [@dim, @dim + 1]
        column: 0
        vTexture: [@vFbs, gl.NEATEST]
        pressureTexture: [@pressureFbs, gl.NEATEST]
      vertexData: 'quad'
      target: @vFbs

    gpu.programs.applyPressure.draw
      uniforms:
        bufSize: [@dim + 1, @dim]
        column: 1
        vTexture: [@uFbs, gl.NEATEST]
        pressureTexture: [@pressureFbs, gl.NEATEST]
      vertexData: 'quad'
      target: @uFbs

  shouldBackupVelocity: ->
    0

  applyExternalForces: (deltaT)=>
    prog = gpu.programs.applyExternalForces.draw
      uniforms:
        bufSize: [@dim + 1, @dim]
        deltaT: deltaT
        acc: @gravity[0]
        dragging: @dragging * 1
        mouseCoord: @mouseCoord
        vTexture: [@uFbs, gl.NEATEST]
        isU: 1
        strength: @mouseStrength
      vertexData: 'quad'
      target: @uFbs
    prog = gpu.programs.applyExternalForces.draw
      uniforms:
        bufSize: [@dim, @dim + 1]
        deltaT: deltaT
        acc: @gravity[1]
        dragging: @dragging * 1
        mouseCoord: @mouseCoord
        vTexture: [@vFbs, gl.NEATEST]
        isU: 0
        strength: @mouseStrength
      vertexData: 'quad'
      target: @vFbs

  extrapolate: =>
    gpu.programs.extrapolate.draw
      uniforms:
        bufSize: [@dim, @dim + 1]
        column: 0
        vTexture: [@vFbs, gl.LINEAR]
      target: @vFbs
      vertexData: 'quad'
    gpu.programs.extrapolate.draw
      uniforms:
        bufSize: [@dim + 1, @dim]
        column: 0
        vTexture: [@uFbs, gl.LINEAR]
      target: @uFbs
      vertexData: 'quad'

  applyBoundaryCondAndMarkValid: =>
    gpu.programs.applyBoundaryCondAndMarkValid.draw
      uniforms:
        bufSize: [@dim, @dim + 1]
        column: 0
        vTexture: @vFbs
        cellTexture: [@cellsFb, gl.LINEAR]
      target: @vFbs
      vertexData: 'quad'
    gpu.programs.applyBoundaryCondAndMarkValid.draw
      uniforms:
        bufSize: [@dim + 1, @dim]
        column: 1
        vTexture: @uFbs
        cellTexture: [@cellsFb, gl.LINEAR]
      target: @uFbs
      vertexData: 'quad'

  advectVelocity: (deltaT)=>
    gpu.programs.advect.draw
      uniforms:
        bufSize: [@dim, @dim]
        column: 0
        deltaT: deltaT
        uTexture: [@uFbs, gl.LINEAR]
        vTexture: [@vFbs, gl.LINEAR]
      vertexData: 'quad'
      target: @vFbs.target

    gpu.programs.advect.draw
      uniforms:
        bufSize: [@dim, @dim]
        column: 1
        deltaT: deltaT
        uTexture: [@uFbs, gl.LINEAR]
        vTexture: [@vFbs, gl.LINEAR]
      vertexData: 'quad'
      target: @uFbs.target

    @uFbs.swap()
    @vFbs.swap()

  step: (deltaT)=>
    @moveMarkers(deltaT)
    @markCells()
    @applyExternalForces(deltaT)
    @applyBoundaryCondAndMarkValid()
    @extrapolate()
    @advectVelocity(deltaT)
    @buildSystem()
    @poissonSolver.solve(@systemFb, @pressureFbs)
    @applyPressure()
    @renderParticles()
    gpu.plotTexture @backBuffer.texture
# gpu.plotTexture system.texture
# gpu.plotTexture @pressureFbs.source.texture
# gpu.plotTexture @vFbs.target.texture, [0, -1]

  simulate: =>
    @initialize()
    setInterval ()=>
          @step 0.01
      , 0

class PIC extends MAC
  constructor: ->
    window.gpu = new GPU()
    programs = @getPrograms()
    gpu.initialize programs
    @initialOffset = [0.05, 0.02]

    @flipAlphaPerSecond = 0.0006
    @dim = parseFloat(settings.resolution)
    @particleFbs = new DoubleFramebuffer(@dim, @dim)
    @pressureFbs = new DoubleFramebuffer(@dim, @dim, 1)
    @uFbs = new DoubleFramebuffer(@dim + 1, @dim)
    @vFbs = new DoubleFramebuffer(@dim, @dim + 1)
    @cellsFb = new Framebuffer(@dim, @dim)
    @systemFb = new Framebuffer(@dim, @dim)
    @backBuffer = new Framebuffer(canvas.width, canvas.height, 1)
    @poissonSolver = new PoissonSolver(@dim)
    @gravity = [0, -1]
    @t = 0.0
    @simulate()
    @initializeMouse()


  getPrograms: ->
    ['initialize', 'iterate', 'points',
      'markCells', 'buildSystem', 'applyExternalForcesPIC',
      'jacobiSolver', 'advect', 'applyBoundaryConditions',
      'extrapolate', 'jacobiSolver', 'applyPressure', 'moveParticles',
      'scatterVelocity', 'normalizeVelocity', 'resample', 'applyExternalForces'
    ]

  moveParticles: (deltaT)=>
    gpu.programs.moveParticles.draw
      uniforms:
        bufSize: [@dim, @dim]
        deltaT: deltaT
        uTexture: [@uFbs, gl.LINEAR]
        vTexture: [@vFbs, gl.LINEAR]
        particleTexture: [@particleFbs, gl.NEAREST]
      vertexData: 'quad'
      target: @particleFbs

  applyExternalForcesPIC: (deltaT)=>
    gpu.programs.applyExternalForcesPIC.draw
      uniforms:
        bufSize: [@dim, @dim]
        gravity: @gravity
        deltaT: deltaT
        particleTexture: [@particleFbs, gl.NEAREST]
      vertexData: 'quad'
      target: @particleFbs

  rasterize: =>
    rasterizeCompoment = (isU, fbs)=>
      prog = gpu.programs.scatterVelocity.use().setUniforms
        bufSize: [@dim, @dim]
        isU: isU
        texture: [@particleFbs, gl.NEAREST]

      fbs.target.bindFB().clear()
      gl.bindBuffer(gl.ARRAY_BUFFER, @pointIdBuffer)
      gl.vertexAttribPointer(prog.attributes.id, @pointIdBuffer.itemSize, gl.FLOAT, false, 0, 0)
      gl.enable gl.BLEND
      gl.blendFunc gl.SRC_ALPHA, gl.ONE
      gl.drawArrays gl.POINTS, 0, @pointIdBuffer.numItems
      gl.disable gl.BLEND
      fbs.swap()

      gpu.programs.normalizeVelocity.draw
        uniforms:
          bufSize: [@dim + (isU), @dim + (1 - isU)]
          vTexture: fbs
          backup: 1
        target: fbs
        vertexData: 'quad'

    rasterizeCompoment(1, @uFbs)
    # gpu.plotTexture @uFbs.source.texture, [-1, 0]
    rasterizeCompoment(0, @vFbs)

  getFlipAlpha: (deltaT)=>
    return Math.pow(@flipAlphaPerSecond, deltaT)

  resample: (deltaT) =>
    gpu.programs.resample.draw
      uniforms:
        bufSize: [@dim, @dim]
        uTexture: [@uFbs, gl.LINEAR]
        vTexture: [@vFbs, gl.LINEAR]
        flipAlpha: @getFlipAlpha(deltaT)
        particleTexture: [@particleFbs, gl.NEAREST]
      vertexData: 'quad'
      target: @particleFbs

  applyBoundaryConditions: =>
    gpu.programs.applyBoundaryConditions.draw
      uniforms:
        bufSize: [@dim, @dim + 1]
        column: 0
        vTexture: @vFbs
        cellTexture: [@cellsFb, gl.LINEAR]
      target: @vFbs
      vertexData: 'quad'
    gpu.programs.applyBoundaryConditions.draw
      uniforms:
        bufSize: [@dim + 1, @dim]
        column: 1
        vTexture: @uFbs
        cellTexture: [@cellsFb, gl.LINEAR]
      target: @uFbs
      vertexData: 'quad'

  substep: (deltaT) =>
    @markCells()
    @rasterize()
    @applyExternalForces(deltaT)
    @applyBoundaryConditions()
    @buildSystem()
    @poissonSolver.solve(@systemFb, @pressureFbs)
    @applyPressure()
    @resample(deltaT)
    @moveParticles(deltaT)

  step: =>
    deltaT = settings.timeStep
    gpu.timeingStats.end()
    gpu.fpsStats.end()
    gpu.timeingStats.begin()
    gpu.fpsStats.begin()
    steps = settings.substeps
    for i in [1..steps]
      @substep(deltaT / steps)
    @renderParticles()
    gpu.plotTexture @backBuffer
    requestAnimationFrame @step

  simulate: =>
    @initialize()
    requestAnimationFrame @step

class PoissonSolver
  constructor: (@dim)->
    @fbs = (new Framebuffer(@dim, @dim) for i in [1..2])
    @first = true

  solve: (systemFb, pressureFbs)=>
    if @first
      pressureFbs.source.bindFB().clear([0.5, 0, 0, 0])
      @first = false

    iterations = parseInt(settings.iterations)
    for i in [1..iterations]
      gpu.programs.jacobiSolver.draw
        uniforms:
          bufSize: [@dim, @dim]
          systemTexture: systemFb
          pressure: pressureFbs
        target: pressureFbs
        vertexData: 'quad'

window.PoissonSolver = PoissonSolver
window.Fluid = PIC
