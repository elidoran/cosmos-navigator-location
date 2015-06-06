# Nav is the main object for all cosmos:navigator packages
# this package is the base package all others are built from.
Nav =
  # tells if Nav is currently running
  running: false
  # (non-reactive) a string containing the browser location's path/query/hash
  location: null
  # reactive version of the above value
  _location: new ReactiveVar()
  # convenience function to set both location values
  _setLocations: (location) -> @location = location ; @_location.set location
  # all reactive getters
  get:
    # returns reactive value of location
    location: -> Nav._location.get()
  # all setters
  set:
    # changes the current location to the specified one
    location: (newLocation) -> Nav._newState newLocation

  # adds actions to call when the location changes
  onLocation: (action) -> # TODO: validate it's a function
    Tracker.autorun (c) ->
      context = location:Nav.get.location()
      if not c.firstRun and context.location?
        action.call context, context.location, c
    return

  # use history to move back `count` number of times
  # TODO: ensure we don't move back passed Nav loading?
  back: (count) -> @history.back count

  # add more state info to the current state
  addState: (moreState) -> @_putState Nav.state, moreState

  # set state in the browser's push api for the current location
  setState: (state={}) -> @_putState state

  # configure with options and set location to current browser location
  # triggering actions
  start: (options) ->
    @_setup options
    @running = true
    @_setLocations @_buildLocation()
    return true

  # remove listeners which essentially stops this from doing anything
  stop: () ->
    @running = false
    # remove event listeners
    document.removeEventListener @_clickType(), @_handleClick, false
    window.removeEventListener 'popstate', @_handlePopstate, false
    return true # shows we successfully completed the stop() function

  # bind function so calling it has the `Nav` as the `this`
  _bindToNav: (listener) ->
    fn = listener.bind Nav
    fn.isBoundToNav = true
    return fn

  # uses the browser's location object to build the current location
  _buildLocation: -> # TODO: shouldn't we put a '#' before location.hash ?
    @_the.location.pathname + @_the.location.search + @_the.location.hash

  # sets click event based on existence of `ontouchstart`
  _clickType: -> if document?.ontouchstart? then 'touchstart' else 'click'

  # TODO: unused
  # decode value
  _decodeThis: (value) ->
    if typeof value isnt 'string' then return value
    decodeURIComponent value.replace /\+/g,' '

  #
  _elementPath: (el) ->
    path = el.pathname + el.search + (el?.hash ? '')
    pattern = /^\/[a-zA-Z]:\//
    path = path.replace pattern, '/' if process? and path.match pattern
    return path

  # listener for popstate events. builds location and sets it into values
  # triggering actions
  _handlePopstate: (event) ->
    unless document.readyState is 'complete' then return
    console.log 'event.state:',event?.state
    @_setLocations @_buildLocation()
    return

  # NOTE: mplementation basically from visionmedia/pagejs
  # listener for click events. filters out clicks which we ignore handling
  # such as 'mailto:'.
  _handleClick: (event) ->
    if @_which event isnt 1 or
      event?.metaKey? or event?.ctrlKey? or event?.shiftKey? or
      event.defaultPrevented
        return

    el = event.target # TODO: better way to find parent anchor element?
    until not el? or el?.nodeName is 'A' then el = el?.parentNode
    unless el?.nodeName is 'A' then return

    # Ignore if tag has: 1. "download" attribute; 2. rel="external" attribute
    if el.hasAttribute 'download' or el.getAttribute 'rel' is 'external'
      return

    link = el.getAttribute 'href'
    if el.pathname is @_the.location.pathname and (el?.hash or link is '#')
      return

    if link?.indexOf('mailto:') > -1 then return

    if el?.target then return

    if el?.origin? and el.origin isnt @_origin() then return
    else if el?.href?.indexOf(@_origin()) isnt 0 then return

    path = @_elementPath el

    # TODO: figure out why they coded their section so strangely... this is a
    # close approximation...i'm not using a base path yet, so...
    #if base?.length > 0 and path.indexOf base is 0 then return #hashbang thing removed

    event.preventDefault()

    if path is @location then return # if new path is same as old path...

    @_newState path

    return

  # create a new state by pushing it onto history and then set the new location
  _newState: (location, state) ->
    unless location?
      location = state?.location ? @_buildLocation()
    @history.pushState state, document.title, location
    @_setLocations location
    return true

  # get the origin of the current location URL
  _origin: ->
    # try getting from the browser's location object
    origin = @_the.location?.origin
    # if we didn't get it above...
    unless origin?
      # build it from parts
      origin = @_the.location.protocol + '//' + @_the.location.hostname +
        if @_the.location?.port? then ':' + @_the.location.port else ''
    return origin

  _putState: (state, extraState={}) ->
    location = state?.location ? @_buildLocation()
    Nav.state = _.extend state, moreState
    @history.replaceState Nav.state, document.title, location
    return

  # setup Nav based on options.
  _setup: (options) -> # TODO: base path, hashbang. use @_decode
    @_the =
      # TODO: or, store the history.length value, and don't go before that...
      locationCount: 0 # TODO: use this ;)
      location: window?.history?.location ? window.location

    # store History object on Nav. If unavailable, put in a NOOP placeholder
    @history = window?.history ? {
      pushState:(->), replaceStart:(->), back:(->), forward:(->), go:(->)
    }

    @_decode = unless options?.decode then ((v)->v) else @_decodeThis

    unless options?.click is false # TODO: clicks element selector?
      @_handleClick = @_bindToNav @_handleClick
      document.addEventListener @_clickType(), @_handleClick, false

    unless options?.popstate is false
      @_handlePopstate = @_bindToNav @_handlePopstate
      window.addEventListener 'popstate', @_handlePopstate, false

    return true

  # get the which/button value
  _which: (event) -># TODO:? shorten to: event?.which ? window?.event?.button
    event ?= window?.event
    return event?.which ? event.button
