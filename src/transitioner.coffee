Transitioner = 
  segues: {}
  next: null
  current: null
  animating: false
  after: null
  go: (args...) ->
    if @animating
      @after = -> FlowRouter.go.apply(FlowRouter, args)
    else
      FlowRouter.go.apply(FlowRouter, args)    
  segue: (obj) ->
    unless obj.from of @segues
      @segues[obj.from] = {}
    @segues[obj.from][obj.to] = obj
  componentWillAppear: (context, done) ->
    # console.log context.displayName, "componentWillAppear"
    @current = context
    @animating = true
    action = @segues[null]?[context.displayName]?.action
    if action 
      action(null, context, =>
        @animating = false
        done()
        @after?()
        @after = null
      ) 
    else 
      @animating = false
      done()      
      @after?()
      @after = null
  componentWillEnter: (context, done) ->
    # console.log context.displayName, "componentWillEnter"
    @next = context
    @animating = true
    before = @segues[@current?.displayName]?[@next.displayName]?.before
    if before then before(@current, @next, done) else done()
  componentWillLeave: (done) ->
    # console.log @current.displayName, "componentWillLeave"
    action = @segues[@current?.displayName]?[@next.displayName]?.action
    if action
      action(@current, @next, =>
        @current = @next
        @next = null
        @animating = false
        done()
        @after?()
        @after = null
      )
    else 
      @current = @next
      @next = null
      @animating = false
      done()
      @after?()
      @after = null

  mixin: (displayName) ->
    componentWillAppear: (done) ->
      Transitioner.componentWillAppear(_.extend(this, {displayName}), done)
    componentWillEnter: (done) ->
      Transitioner.componentWillEnter(_.extend(this, {displayName}), done)
    componentWillLeave: (done) ->
      Transitioner.componentWillLeave(done)