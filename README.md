# Cosmos Navigator Location [![Build Status](https://travis-ci.org/elidoran/cosmos-navigator-location.svg?branch=master)](https://travis-ci.org/elidoran/cosmos-navigator-location)

Browser location as a reactive value to be the root of a new router system.

Uses both `click` and `popstate` events to track the current browser location.

Allows setting state into `History` via `Nav.setState(Object)`.

Retains simplicity by avoiding extra work, such as:

1. processing location into parts: path, query, fragment
2. storing and calling exit/entry callbacks
3. storing any info into the State for itself
4. handling routes and route parameters
5. performing subscriptions

I made this minimalistic so it avoids doing any work which isn't desired. Then
we can add functionality by adding packages. It's primary purpose is to
use click and popstate events to put the location into a reactive var;
thus bringing the browser location into the Meteor reactivity realm.

Cosmos Navigator packages are built upon this package.  

Inspired by [visionmedia/page.js](http://github.com/visionmedia/page.js) and
[meteorhacks/flow-router](http://github.com/meteorhacks/flow-router) (which
uses pagejs).

## Install

    $ meteor add cosmos:navigator-location

You may use this package alone and provide all other functionality in your own way
by reacting to location changes.

You may use other Cosmos Navigator packages to fulfill the common functionality such as callbacks, routing, and subscriptions.

## Usage: Nav.onLocation(fn)

A convenience function which will call your function when the `location` changes.
It wraps your function in a `Tracker.autorun()` where it reactively gets the
location to supply to your function.

The computation is returned by `Nav.onLocation()`, and, the computation is
provided as the second argument to your function.

```coffeescript
Nav.onLocation (theLocation) ->
  console.log 'the new location is: ',theLocation

Nav.onLocation (theLocation, computation) ->
  console.log 'the new location is: ',theLocation
```

## Usage: Tracker.autorun(fn)

Create your own tracker and access the location variable reactively.

```coffeescript
Tracker.autorun (computation) ->
  location = Nav.get.location()
  console.log 'the new location is: ',theLocation
```

## API

### Nav.location

The *non-reactive* access to the current location.

Note: It's not a function, which is a *hint* it's non-reactive.

```coffeescript
location = Nav.location
```

### Nav.get.location()

The *reactive* access to the current location.

Note: It *is* a function, which is a hint it's *reactive*.

```coffeescript
location = Nav.get.location()
```

### Nav.set.location(string)

Change the current location of the browser to the specified location.

```coffeescript
Nav.set.location '/blog/12345'
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
object = Nav.history.state
```

### Nav.running

The *non-reactive* access to the `running` value.

Note: It's not a function, which is a *hint* it's non-reactive.

```coffeescript
running = Nav.running
```

### Nav.get.running()

Reactive boolean representing the Nav's `running` state. After `Nav.start()` it is `true`. After `Nav.stop()` it is `false`.

Note: `Nav.start()` is called automatically as part of `Meteor.startup()`.
See [Nav.start(Object)](#nav-startobject)

Note: It *is* a function, which is a hint it's *reactive*.

```coffeescript
running = Nav.get.running()
```

### Nav.start(Object)

Nav will use options in the provided Object to initialize and move to its running
state. Unless options specify otherwise, it will add both `click` and `popstate`
event listeners.

Note: `Nav.start()` is called automatically as part of `Meteor.startup()` via `Running.onChange()`.
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

## Hashbang paths

Visionmedia's page.js allows configuring use of the hashbang (#!) at the front of
the path. I haven't implemented it in this package, tho it is possible to do.


## Cosmos Navigator packages

1. *[Unpublished]* navigator : aggregates navigator packages to create the common router functionality
2. *[Unpublished]* pipeline : changes `onLocation` to create an ordered executable pipeline of actions via cosmos:chain
3. *[Unpublished]* parse : parses the location into parts
4. *[Unpublished]* routes : allows specifying traditional routes via `Nav.route()`
5. *[Unpublished]* view : renders layout and template views
6. *[Unpublished]* lasimii : a special package using a location pattern convention to simplify routing and rendering

## MIT License
