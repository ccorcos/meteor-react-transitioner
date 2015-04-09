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
