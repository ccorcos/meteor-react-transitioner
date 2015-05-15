# Meteor React Transitioner

This pacakge helps execute page transitions with React using the TransitionGroup addon, VelocityJS, and FlowRouter.

Still a WIP

## Getting Started

    meteor add ccorcos:react-transitioner

The basic idea is to wrap your element in a TransitionGroup element (make sure it has a key as well).

```coffee
FlowRouter.route '/search',
  action: (params, queryParams) ->
    TransitionGroup = React.createFactory(React.addons.TransitionGroup)
    React.render(TransitionGroup({}, React.factories.Search({key:'search'})), document.body)
```

Then in your component, use the `Transitioner.mixin` to register callbacks to `componentWill[Appear|Enter|Leave]`

    mixins: [Transitioner.mixin('Home')]

The name you use here is how you reference them when creating a segue.

Segues work like this. First thing that happens when you transition is the next component is inserted. So typically you'll want to hide it immediately `before` it shows up. Then you'll want to do all the animations in `action`.

```coffee
Transitioner.segue
  from: 'Search'
  to: 'Home'
  before: (Search, Home, done) ->
    # initially hide Home
    $(Home.refs.Body.getDOMNode()).css('opacity',0)
    done()
  action: (Search, Home, done) ->
    animateRefs(Search.refs.box, Home.refs.box)
    $(Search.refs.Header.refs.searchIcon.getDOMNode()).velocity({opacity:[0,1], easing:'ease-out', duration:200}, {complete: =>
      $(Search.refs.Body.getDOMNode()).css('opacity',1)
      $(Home.refs.Header.refs.homeIcon.getDOMNode()).velocity({opacity:[0,1], easing:'ease-out', duration:200}, {complete: done})
    })
```


One of the coolest animations, I think, is my measuring where a certain element goes in the next page and animating it there. Here's how I do it:

```coffee
rgb2hex = (rgb) ->
  rgb = rgb.match(/^rgba?[\s+]?\([\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?/i)
  if rgb and rgb.length == 4 then '#' + ('0' + parseInt(rgb[1], 10).toString(16)).slice(-2) + ('0' + parseInt(rgb[2], 10).toString(16)).slice(-2) + ('0' + parseInt(rgb[3], 10).toString(16)).slice(-2) else ''

animateRefs = (refFrom, refTo) ->
  node = refFrom.getDOMNode()
  rect = node.getBoundingClientRect()
  style = getComputedStyle(node)
  from = {node, rect, style}

  node = refTo.getDOMNode()
  rect = node.getBoundingClientRect()
  style = getComputedStyle(node)
  to = {node, rect, style}

  animation = {}
  if from.rect.width isnt to.rect.width
    animation.width = to.rect.width
  if from.rect.height isnt to.rect.height
    animation.height = to.rect.height

  if from.rect.left isnt to.rect.left
    animation.translateX = to.rect.left - from.rect.left
  if from.rect.top isnt to.rect.top
    animation.translateY = to.rect.top - from.rect.top

  for attr in ['backgroundColor', 'color']
    if from.style[attr] isnt to.style[attr]
      animation[attr] = rgb2hex(to.style[attr])

  $(from.node).velocity(animation)
```



<!-- 


# React Transitioner

There are basically 3 types of transitions.

## Page Transitions

Suppose you are rendering pages to the `document.body` wrapped in a TransitionGroup. Then we can render `To` with opacity 0, compute the position changes, animate `From` to `To` then remove `From`. The description looks something like this:

    transitioner = 
      from: displayName or *
      to: displayName or *
      action: (From, To, done) ->
        # given the context of the From and To components. 
        # To has just been rendered to the body with opacity 0
        # animate From off coordinated with To in. Async callback


## Scene Transitions

Suppose we are changing the scene within a component. Maybe there are multiple conditional steps in a signup form that you want to meticulously transition in between. We use `this.state.scene` to keep track of the current scene. You can call `this.nextScene` to iniate the transition. These are simple transitions with no overlap. Animate out, then animate in.

    transitioner = 
      from: 'scene1'
      to: 'scene2'
      before: (done) ->
        # given this context
        # animate scene1 out and call the callback
        # scene2 will be inserted
      after: (done) ->
        # given this context
        # animate scene2 in and call the callback


 -->