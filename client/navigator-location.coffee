# Nav is the global object to control the browser location, location state,
# and get its location reactively.
Nav =

  # tells if Nav is currently running
  running: false

  # (non-reactive) a string containing the browser location's path/query/hash
  location: null

  # reactive version of the above value
  _location: new ReactiveVar()

  # convenience function to set both location values
  _setLocations: (location) ->
    @location = location    # non-reactive
    @_location.set location # reactive (triggers trackers)
    # i could emit an event so it's not executed in a tracker, but, i'd need
    # a browser compatible EventEmitter just for this one event.
    # could accept functions and add them to an array to call in sequence...
    # could use Chain
    # it's possible for them to use Tracker.nonreactive() to get out of Tracker,
    # so, let's avoid all the extra code and expect them to do that.

  # returns reactive value of location
  getLocation: -> Nav._location.get()

  # changes the current location to the specified one
  setLocation: (newLocation) -> Nav._newState newLocation # TODO: encode this?

  # adds actions to call when the location changes
  onLocation: (action) -> # TODO: validate it's a function
    Tracker.autorun (c) ->
      # Nav.reload() will trigger this tracker causing this autorun to rerun
      Nav._reloadTracker.depend()
      location = Nav.getLocation()
      if not c.firstRun and location? then action.call Nav, location:location, computation:c
    return

  # use history to move back `count` number of times
  # TODO: ensure we don't move back passed Nav loading?
  back: (count=1) -> @history.go -1 * count

  forward: (count=1) -> @history.go count

  # use in autoruns so reload() can trigger them to run again
  _reloadTracker: new Tracker.Dependency()

  # trigger all onLocation autoruns to rerun
  reload: ->
    Nav.isReload = true
    @_reloadTracker.changed()

  # add more state info to the current state
  addState: (moreState) -> @_putState Nav.state, moreState

  setBasepath: (basepath) -> @basepath = basepath

  # change hashbang implementations to either use hashbangs or not
  setHashbangEnabled: (enabled) -> @_hashbangEnabled = enabled

  # set state in the browser's push api for the current location
  setState: (state={}) -> @_putState state

  # configure with options and set location to current browser location
  # triggering actions
  start: (options) ->
    @_setup options
    @running = true
    location = @_basepathStrip @_hashbangStrip @_buildLocation()
    @_setLocations location
    return true

  # remove listeners which essentially stops this from doing anything
  stop: () ->
    @running = false
    # remove event listeners
    document.removeEventListener @_clickType(), @__handleClick, false
    window.removeEventListener 'popstate', @__handlePopstate, false
    return true # shows we successfully completed the stop() function

  _basepathPrepend: (location) ->
    if @basepath? and location[...@basepath.length] isnt @basepath
      @basepath + location
    else location

  _basepathStrip: (location) ->
    if @basepath? and location[...@basepath.length] is @basepath
      location[@basepath.length..]
    else location

  # uses the browser's location object to build the current location
  _buildLocation: ->
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
    # location *without* basepath and hashbang:
    location = Nav._basepathStrip Nav._hashbangStrip Nav._buildLocation()
    Nav.state = event.state
    Nav._setLocations location
    return

  # NOTE: implementation basically from visionmedia/pagejs
  # listener for click events. filters out clicks which we ignore handling
  # such as 'mailto:'.
  _handleClick: (event) ->

    # return if not a simple click or it's already prevented.
    if Nav._which event isnt 1 or
      event?.metaKey? or event?.ctrlKey? or event?.shiftKey? or
      event.defaultPrevented
        return

    # get anchor element above the clicked element
    el = event.target # TODO: better way to find parent anchor element?
    until not el? or el?.nodeName is 'A' then el = el?.parentNode
    unless el?.nodeName is 'A' then return

    # Ignore if tag has: 1. "download" attribute; 2. rel="external" attribute
    if el.hasAttribute 'download' or el.getAttribute 'rel' is 'external'
      return

    link = el.getAttribute 'href'
    if el.pathname is Nav._the.location.pathname and (el?.hash or link is '#')
      return

    if link?.indexOf('mailto:') > -1 then return

    if el?.target then return

    if el?.origin? and el.origin isnt Nav._origin() then return
    if el?.href?.indexOf(Nav._origin()) isnt 0 then return

    path = Nav._elementPath el

    event.preventDefault()

    if path is Nav.location then return # if new path is same as old path...

    Nav._newState path

    return

  _hashbangPrepend: (location) ->
    # TODO: ensure the specified location starts with a slash after hashbang?
    if @_hashbangEnabled and location[...4] isnt '/#!/' then '/#!' + location
    else location

  _hashbangStrip: (location) ->
    if @_hashbangEnabled and location[...4] is '/#!/' then location[3..] else location

  # create a new state by pushing it onto history and then set the new location
  # used by Nav.setLocation() and click event handler.
  _newState: (location, state) ->
    Nav.state = state

    # location *with* basepath and hashbang
    fullLocation = @_basepathPrepend @_hashbangPrepend location

    # location *without* basepath and hashbang:
    shortLocation = @_basepathStrip @_hashbangStrip location

    @history.pushState state, document.title, fullLocation

    @_setLocations shortLocation

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
    if state?
      Nav.state = state
      state[key] = value for own key,value of extraState
    else Nav.state = extraState

    # for basepath and hashbang just build location from the browser's location
    location = @_buildLocation()
    @history.replaceState Nav.state, document.title, location
    return

  # setup Nav based on options.
  _setup: (options) -> # TODO: base path, hashbang. use @_decode
    @_the =
      # TODO: or, store the history.length value, and don't go before that...
      locationCount: 0 # TODO: use this ;)
      location: window?.history?.location ? window.location

    # store History object on Nav.
    # if there is a history pushState function then we're fine.
    if window?.history?.pushState?
      @history = window.history

    # there's no push state API, so, enable hashbangs now and provide an
    # alternate history implementation.
    # TODO: there's a history push state polyfill. add that with a conditional
    #       comment to support IE browsers. what about other old browsers? hmm.
    else
      @_setHashbangEnabled true
      # add NOOP implementations.
      # TODO:
      #  implement these for browsers which don't have a history API.
      #  we'd have to track our
      #  pushState should change the browser location with a hashbang location
      #  replaceState should only update the stored state for the location.
      #
      @history = {
        pushState:(->), replaceState:(->), back:(->), forward:(->)
      }

    @_decode = unless options?.decode then ((v)->v) else @_decodeThis

    unless options?.click is false # TODO: clicks element selector?
      document.addEventListener @_clickType(), @_handleClick, false

    unless options?.popstate is false
      window.addEventListener 'popstate', @_handlePopstate, false

    if options?.hashbang is true then @_setHashbangEnabled true

    if options?.basepath? then @_setBasepath options.basepath

    return true

  # get the which/button value
  _which: (event) -> # TODO:? shorten to: event?.which ? window?.event?.button
    event ?= window?.event
    return event?.which ? event.button
