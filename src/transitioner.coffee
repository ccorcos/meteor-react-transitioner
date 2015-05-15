_ = lodash

flip2 = (f) ->
  (a,b) =>
    f?(b,a)


# A daisy function is defined as (done) -> done()
daisy = {}

# if the function is undefined, we just want to chain past it
daisy.maybe = (f) ->
  if _.isFunction(f) then f else (done) -> done?()

# wrap a function as a daisy function
daisy.wrap = (f) ->
  (done) ->
    f?()
    done?()

# compose the daisy compose is defined as
# [a,b,c,d] -> done -> a(-> (b -> c( -> d(done))))
daisy.compose = () ->
  args = R.compose(R.map(daisy.maybe), R.reverse, _.toArray)(arguments)
  first = _.first(args)
  rest = _.rest(args)

  # if reducing in reverse order, this will build the chain
  # acc = -> d(done)
  # acc = -> c -> d(done)
  # acc = -> b -> c -> d(done)
  reducer = (acc, func) ->
    -> func(acc)

  (done) ->
    f = R.reduce(reducer, (-> first(done)), rest)
    f()

# call the daisy chain
# [a,b,c,d] -> a( -> b( -> c(d)))
daisy.chain = () ->
  # [a,b,c,d]
  # a ->
  #   b ->
  #     c(d)
  args = _.toArray(arguments)
  beginning = args[0...args.length-1]
  last = _.last(args)
  daisy.compose.apply(null, beginning)(last)

# functions for waiting/throttling functions
daisy.wait = {}

# queue up daisy function calls when daisy function is busy
# n = -1 is an infinite queue
# n = 0 is no queue
# n = 1 is the latest call
daisy.wait.queueN = (func, n) ->
  queue = []
  busy = false

  done = ->
    if queue.length > 0
      queue.pop()()
    else
      busy = false

  () ->
    args = _.toArray(arguments)  
    complete = daisy.utils.fmerge(_.first(args), done)
    args = _.rest(args)

    if busy and n > 0
      queue.unshift -> func.apply(null, [complete].concat(args))
      while queue.length > n
        queue.pop()
    else if busy and n < 0
      queue.unshift -> func.apply(null, [complete].concat(args))
    else if not busy
      busy = true
      func.apply(null, [complete].concat(args))


# drop any function calls while busy
daisy.wait.drop = (func) ->
  daisy.wait.queueN(func, 0)

# queue all function calls while busy
daisy.wait.queue = (func) ->
  daisy.wait.queueN(func, -1)

# queue the latest function call while busy
daisy.wait.latest = (func) ->
  daisy.wait.queueN(func, 1)

# a daisy function that caller. fcall(done, f, args...) -> f(done, args...)
# daisy.wait fcall(done, f) -> ()
daisy.fcall = (done, f) ->
  args = _.toArray(arguments)
  args = args[2...args.length]
  daisy.maybe(f).apply(null, [done].concat(args))


daisy.utils = {}
daisy.utils.fmerge = () ->
  args = _.toArray(arguments)
  -> _.map args, (f) -> f?()

daisy.tools = {}

invoker = ->
  f = null
  (func) ->
    if f then f() else f = func

daisy.tools.invoker = invoker

class writer 
  constructor: ->
    this.arr = []
  write: (n) ->
    daisy.wrap => this.arr.push(n)
  controlledWrite: () ->
    (done, invoker, n) =>
      this.arr.push(n)
      invoker(done)

daisy.tools.writer = writer

daisy.tests = {}
daisy.tests.chain = ->
  w = new daisy.tools.writer()
  daisy.chain(w.write(1), w.write(2), w.write(4), w.write(3))
  R.eqDeep(w.arr, [1,2,4,3])

daisy.tests.chain = ->
  w = new daisy.tools.writer()
  daisy.chain(w.write(1), w.write(2), w.write(4), w.write(3))
  R.eqDeep(w.arr, [1,2,4,3])

daisy.tests.drop = ->
  w = new daisy.tools.writer()
  f = _.partial(daisy.wait.drop(w.controlledWrite()), _.noop)
  invoker = daisy.tools.invoker
  done = [invoker(), invoker(), invoker(), invoker(), invoker()]
  f(done[0], 0) # write
  f(done[1], 1)
  f(done[2], 2)
  done[0]()     # free
  done[1]()
  f(done[3], 3) # write
  done[2]()
  done[3]()     # free
  f(done[4], 4) # write
  done[4]()     # free
  R.eqDeep(w.arr, [0,3,4])

daisy.tests.latest = ->
  w = new daisy.tools.writer()
  f = _.partial(daisy.wait.latest(w.controlledWrite()), _.noop)
  invoker = daisy.tools.invoker
  done = [invoker(), invoker(), invoker(), invoker(), invoker()]
  f(done[0], 0) # write 0
  f(done[1], 1)
  f(done[2], 2) 
  done[0]()     # next 2
  done[1]()
  f(done[3], 3) 
  done[2]()     # next 3
  done[3]()     # free
  f(done[4], 4) # write 4
  done[4]()     # free
  R.eqDeep(w.arr, [0,2,3,4])

daisy.tests.queue = ->
  w = new daisy.tools.writer()
  f = _.partial(daisy.wait.queue(w.controlledWrite()), _.noop)
  invoker = daisy.tools.invoker
  done = [invoker(), invoker(), invoker(), invoker(), invoker()]
  f(done[0], 0)
  f(done[1], 1)
  f(done[2], 2)
  done[0]()
  done[1]()
  f(done[3], 3)
  done[2]()
  done[3]()
  f(done[4], 4)
  done[4]()
  R.eqDeep(w.arr, [0,1,2,3,4])


@daisy = daisy



# segue types:
# 1. from, to, and action
# 2. from, to, in, out
# 3. name,     in, out

# route segue types: 1, 3
# scene segue types: 2, 3

# action  = (done, fromContext, toContext) ->
# in, out = (done) ->

defineSegue = (segues, obj) ->
  if obj.from or obj.to
    if _.isArray(obj.from)
      _.map obj.from, (from) ->
        defineSegue(segues, R.assoc('from', from, obj))
    else
      unless obj.from of segues
        segues[obj.from] = {}
      if _.isArray(obj.to)
        _.map obj.to, (to) ->
          defineSegue(segues, R.assoc('to', to, obj))
      else
        segues[obj.from][obj.to] = obj
  else
    if _.isArray(obj.name)
      _.map obj.name, (name) ->
        defineSegue(segues, R.assoc('name', name, obj))
    else
      unless '*' of segues
        segues['*'] = {}
      segues['*'][obj.name] = obj
      unless obj.name of segues
        segues[obj.name] = {}
      segues[obj.name]['*'] = obj

Transitioner =

  routeSegues: {}

  currentComponent: null
  nextComponent: null
  
  routeSegue: (obj) -> defineSegue(@routeSegues, obj)


  # we can't just wait on doRouteSegue. We also have the FlowRouter mixin
  # that will prevent the next route from rendering until the current
  # segue is done. Thus we are waiting on arbirary maybe(daisy) function
  # calls
  callLatest: daisy.wait.latest(daisy.fcall)

  doRouteSegue: (done, fromPath, toPath, fromContext, toContext) ->
    transition = @routeSegues[fromPath]?[toPath]?.action
    if transition
      # console.log fromPath, toPath
      @callLatest(done, transition, fromContext, toContext)
    else
      # console.log fromPath, '*'
      # console.log '*', toPath
      animateOut = @routeSegues[fromPath]?['*']?.out?.bind(fromContext)
      animateIn = @routeSegues['*']?[toPath]?.in?.bind(toContext)
      unless animateIn
        animateIn = daisy.wrap ->
          $(toContext.getDOMNode()).css('opacity',1)
      @callLatest(done, ((next) ->
        daisy.chain(
          animateOut
          animateIn
          next
        )
      ))


  componentWillAppear: (context, done) ->
    @currentComponent = context
    @doRouteSegue(done, '*', context.displayName, null, context)
    
  componentWillEnter: (context, done) ->
    @nextComponent = context
    $(context.getDOMNode()).css('opacity', 0)
    done()
   
  componentWillLeave: (done) ->
    complete = =>
      @currentComponent = @nextComponent
      @nextComponent = null
      done()

    fromPath = @currentComponent?.displayName
    toPath = @nextComponent?.displayName
    fromContext = @currentComponent
    toContext = @nextComponent

    @doRouteSegue(complete, fromPath, toPath, fromContext, toContext)

  # react
  routeMixin: (displayName) ->
    self = this
    componentWillAppear: (done) ->
      self.componentWillAppear(_.extend(this, {displayName}), done)
    componentWillEnter: (done) ->
      self.componentWillEnter(_.extend(this, {displayName}), done)
    componentWillLeave: (done) ->
      self.componentWillLeave(done)
    
  # flow-router
  routeMiddleware: (path, next) ->
    # wait til the animation is done to go to the next route. 
    # drop this route if another one comes in before the the current segue is done
    Transitioner.callLatest(next)

  sceneMixin:
    componentWillMount: ->
      @sceneSegues = {}
      # animate to the next scene
      nextScene = daisy.wait.queue (done, name) =>
        animateOut = null
        animateIn = null
        segue = @sceneSegues[@state.scene]?[name]
        if segue
          animateOut = segue.out.bind(this)
          animateIn = segue.in.bind(this)
        else
          animateOut = @sceneSegues[@state.scene]?['*'].out?.bind(this)
          animateIn = @sceneSegues['*']?[name]?.in?.bind(this)

        daisy.chain(
          animateOut
          daisy.wrap => @setState({scene:name})
          animateIn
          done
        )

      # we want to call nextScene(name) rather than nextScene(callback, name)
      # @nextScene = _.partial(nextScene, _.noop)
      @nextScene = flip2.bind(this)(nextScene)

      # a function that returns an array of segues
      for segue in @getSceneSegues?()
        @sceneSegue(segue)          

    sceneSegue: (obj) -> defineSegue(@sceneSegues, obj)

    renderScene: () ->
      f = @getScenes?()?[@state.scene]?.bind(this)
      if f
        f()
      else
        console.warn "Invalid scene", @state.scene
        false

  stateMixin:
    componentWillMount: ->
      @stateSegues = {}
      segues = @getStateSegues?()
      if segues
        _.map segues, (obj, name) =>
          @stateSegues[name] = daisy.wait.latest (done, value) =>
            if @state[name] isnt value
              s = {}
              s[name] = value
              animateOut = obj.out.bind(this)
              animateIn = obj.in.bind(this)
              unless @state[name]
                # dont animate out if theres nothing there
                animateOut = null
              daisy.chain(
                animateOut
                daisy.wrap => @setState(s)
                animateIn
                done
              )
            else
              done()

    nextState: (key, value, func) ->
      @stateSegues[key]?(func, value)

  velocityMixin:
    $refs: (refs) ->
      getDOMNode = (ref) => @refs[ref]?.getDOMNode?()
      truthy = (x) -> not (not x)
      getRefs = R.compose(R.filter(truthy), R.map(getDOMNode))
      $ getRefs(refs)
    $ref: (ref) ->
      @$refs([ref])
    nthCallOf: (nth, func) ->
      n = 0
      () ->
        n += 1
        if n is nth then func()
    animate: _.curry (refs, transition, options, done) ->
      @$refs(refs).velocity(transition, R.merge({display:null,complete:done}, options))



@Transitioner = Transitioner