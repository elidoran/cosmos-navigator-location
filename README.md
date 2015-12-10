# Cosmos Navigator Location [![Build Status](https://travis-ci.org/elidoran/cosmos-navigator-location.svg?branch=master)](https://travis-ci.org/elidoran/cosmos-navigator-location)

Browser location as a reactive value as the simple root of a new router system.

Uses both `click` and `popstate` events to track the current browser location.

Allows setting state into `History` via `Nav.setState(Object)` and `Nav.addState(Object)`.

Maximum simplicity by avoiding extra work, such as:

1. processing location into parts: path, query, fragment
2. storing and calling exit/entry callbacks
3. storing any info into the State for itself
4. handling routes and route parameters
5. performing subscriptions

I made this minimalistic so it avoids doing any work which isn't desired. Then functionality can be added by adding packages. It's primary purpose is to use click and popstate events to put the location into a reactive var; thus bringing the browser location into the Meteor reactivity realm.

Cosmos Navigator packages are built upon this package.  

Inspired by [visionmedia/page.js](http://github.com/visionmedia/page.js) and
[meteorhacks/flow-router](http://github.com/meteorhacks/flow-router) (which
uses pagejs).

## Install

    $ meteor add cosmos:navigator-location

You may use this package alone and provide all other functionality in your own way
by reacting to location changes.

You may use other Cosmos Navigator packages to fulfill the common functionality such as callbacks, routing, and subscriptions.

TODO: Finish those packages. :)


## Usage: Nav.onLocation(fn)

A convenience function which will call your function when the `location` changes.
It wraps your function in a `Tracker.autorun()` where it reactively gets the
location to supply to your function.

The computation is returned by `Nav.onLocation()`, and, the computation is
also provided in the object argument to your function as `object.computation`.

The location is also in the object argument. The `this` is the Nav object and it has the `location` value in in. So, there are two ways to get the location value.

```coffeescript
Nav.onLocation (info) ->
  console.log 'the new location is: ',info.location
  console.log 'the same location value: ',this.location

Nav.onLocation (info) ->
  console.log 'the computation is: ',info.computation
```

## Usage: Tracker.autorun(fn)

Create your own tracker and access the location variable reactively.

```coffeescript
Tracker.autorun (computation) ->
  # optional: Nav._reloadTracker.depends()  reruns tracker on Nav.reload()
  location = Nav.getLocation()
  console.log 'the new location is: ',location
```

## API

### Nav.location

The *non-reactive* access to the current location.

Note: It's not a function, which is a *hint* it's non-reactive.

```coffeescript
location = Nav.location
```

### Nav.getLocation()

The *reactive* access to the current location.

Note: It *is* a function, which is a hint it's *reactive*.

```coffeescript
location = Nav.getLocation()
```

### Nav.setLocation(string)

Change the current location of the browser to the specified location.

```coffeescript
Nav.setLocation '/blog/12345'
```

### Nav.onLocation(fn)

Register a listener called when the location changes. See [its usage](#usage-navonlocationfn).

### Nav.setState(Object)

Store a state object into the current `History` location.

Note: Object must be serializable. Lookup `History.pushState()`.

```coffeescript
# get some object you want to store in the current history location
object = getSomething()
# store it into the history as the state object
Nav.setState object

# later, when location is loaded again,
# for example, via the back button,
# you can get your object back like this:
object = Nav.state

# in a Nav.onLocation function:
Nav.onLocation -> theState = this.state
# the `this` is the Nav object, and, we set state into Nav.state.
```

### Nav.running

The *non-reactive* access to the `running` value.

Note: It's not a function, which is a *hint* it's non-reactive.

```coffeescript
running = Nav.running
```


### Nav.start(Object)

Nav will use options in the provided Object to initialize and move to its running
state. Unless options specify otherwise, it will add both `click` and `popstate`
event listeners.

Note: `Nav.start()` is called automatically as part of `Meteor.startup()`. If you are using *cosmos:running* to order your startup functions then Nav will use that with id `CosmosRunNav`.

It tests if Nav is already running before calling start so you have the opportunity to call `Nav.start()` with your own options first. Place your function ahead of ours in the Running object like this:

```coffeescript
yourFn = (running) ->
  if running
    options = {} # fill in with your own options
    Nav.start options
# configure the options for Running object
yourFn.options = id:'MyNavStart', before:['CosmosRunNav']
# add it to Running:
Running.onChange yourFn
```

See [cosmos:running](http://github.com/elidoran/cosmos-running) for more details.


### Nav.stop()

Removes both `click` and `popstate` event listeners and sets `running` to false.


## Nav.setHashbangEnabled(boolean)

You may also use a `Nav.start()` option named `hashbang` set to true to enable it.

When enabled, all locations are prefixed with '/#!' when changing *to* them. Also, all locations have that same prefix removed before passing the location value to tracker computations and setting it into `Nav.location`. This way, all actions don't have to care whether hashbangs are being used.


## Nav.setBasepath(basepath)

You may also set a `Nav.start()` string option named `basepath`.

When set, all locations are prefixed with the basepath value when changing to them. If hashbang is also enabled it will be applied to the location *before* prepending the `basepath` value. Also, all locations have the basepath removed before passing the location value to tracker computations and setting it into `Nav.location`. So, all actions don't have to care if there is a basepath.


## Nav.reload()

Calling reload triggers all tracker computations to rerun. Well, all those registered with `Nav.onLocation(fn)`. This essentially reruns all tracker computations on the same location.


## Nav.back(count)

Same as clicking the back button. It accepts a positive number representing how far back to go.


## Nav.forward(count)

Same as clicking the forward button. It accepts a positive number representing how far forward to go.


## MIT License
