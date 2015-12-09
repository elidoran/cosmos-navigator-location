delay = Meteor?.settings?.TEST_DELAY ? 100

location1 = '/some/path'
hashedLocation1 = '/#!' + location1
basepath1 = '/basepath'
basepathLocation1 = basepath1 + location1
basepathHashbangLocation1 = basepath1 + hashedLocation1

reset = ->
  Nav.setHashbangEnabled false
  Nav.setBasepath null
  Nav.setLocation '/'


Tinytest.addAsync 'setLocation', (test, done) ->
  Nav.setLocation location1
  setTimeout (->
    test.equal Nav.location, location1
    test.equal Nav.getLocation(), location1
    test.equal location.pathname, location1
    done()
  ), delay

Tinytest.add 'setHashbangEnabled', (test) ->
  reset()

  Nav.setHashbangEnabled true

  test.equal Nav._hashbangPrepend(location1), hashedLocation1
  test.equal Nav._hashbangPrepend(hashedLocation1), hashedLocation1

  test.equal Nav._hashbangStrip(location1), location1
  test.equal Nav._hashbangStrip(hashedLocation1), location1

  reset()

  test.equal Nav._hashbangPrepend(location1), location1
  test.equal Nav._hashbangPrepend(hashedLocation1), hashedLocation1

  test.equal Nav._hashbangStrip(location1), location1
  test.equal Nav._hashbangStrip(hashedLocation1), hashedLocation1

Tinytest.addAsync 'setLocation with hashbang enabled', (test, done) ->
  reset()

  Nav.setHashbangEnabled true
  Nav.setLocation location1
  setTimeout (->
    test.equal Nav.location, location1
    test.equal Nav.getLocation(), location1
    test.equal location.pathname + location.hash, hashedLocation1
    Nav.setHashbangEnabled false
    done()
  ), delay

Tinytest.add 'setBasepath', (test) ->
  reset()

  Nav.setBasepath basepath1

  test.equal Nav._basepathPrepend(location1), basepathLocation1
  test.equal Nav._basepathPrepend(basepathLocation1), basepathLocation1

  test.equal Nav._basepathStrip(location1), location1
  test.equal Nav._basepathStrip(hashedLocation1), hashedLocation1
  test.equal Nav._basepathStrip(basepathLocation1), location1

  reset()

  test.equal Nav._basepathPrepend(location1), location1
  test.equal Nav._basepathPrepend(basepathLocation1), basepathLocation1

  test.equal Nav._basepathStrip(location1), location1
  test.equal Nav._basepathStrip(hashedLocation1), hashedLocation1
  test.equal Nav._basepathStrip(basepathLocation1), basepathLocation1

Tinytest.addAsync 'setLocation with a basepath', (test, done) ->
  reset()

  Nav.setBasepath basepath1
  Nav.setLocation location1
  setTimeout (->
    test.equal Nav.location, location1
    test.equal Nav.getLocation(), location1
    test.equal location.pathname + location.hash, basepathLocation1
    Nav.setBasepath null
    done()
  ), delay

Tinytest.add 'setBasepath with setHashbangEnabled', (test) ->
  reset()

  Nav.setHashbangEnabled true
  Nav.setBasepath basepath1

  test.equal Nav._basepathPrepend(Nav._hashbangPrepend(location1)), basepathHashbangLocation1

  test.equal Nav._basepathStrip(Nav._hashbangStrip(location1)), location1
  test.equal Nav._basepathStrip(Nav._hashbangStrip(hashedLocation1)), location1
  test.equal Nav._basepathStrip(Nav._hashbangStrip(basepathLocation1)), location1

  reset()

  test.equal Nav._basepathPrepend(Nav._hashbangPrepend(location1)), location1
  test.equal Nav._basepathPrepend(Nav._hashbangPrepend(hashedLocation1)), hashedLocation1
  test.equal Nav._basepathPrepend(Nav._hashbangPrepend(basepathLocation1)), basepathLocation1
  test.equal Nav._basepathPrepend(Nav._hashbangPrepend(basepathHashbangLocation1)), basepathHashbangLocation1

  test.equal Nav._basepathStrip(Nav._hashbangStrip(location1)), location1
  test.equal Nav._basepathStrip(Nav._hashbangStrip(hashedLocation1)), hashedLocation1
  test.equal Nav._basepathStrip(Nav._hashbangStrip(basepathLocation1)), basepathLocation1
  test.equal Nav._basepathStrip(Nav._hashbangStrip(basepathHashbangLocation1)), basepathHashbangLocation1

Tinytest.addAsync 'setLocation with a basepath and hashbang', (test, done) ->
  reset()

  Nav.setHashbangEnabled true
  Nav.setBasepath basepath1
  Nav.setLocation location1
  setTimeout (->
    test.equal Nav.location, location1
    test.equal Nav.getLocation(), location1
    test.equal location.pathname + location.hash, basepathHashbangLocation1
    done()
  ), delay

Tinytest.add 'setState', (test) ->
  reset()

  Nav.setLocation '/set/state'
  Nav.setState some:'value'
  test.isNotNull Nav.state
  test.equal Nav.state.some, 'value'

Tinytest.add 'addState', (test) ->
  Nav.addState another:'value'
  test.isNotNull Nav.state
  test.equal Nav.state.some, 'value'
  test.equal Nav.state.another, 'value'

Tinytest.addAsync 'back()', (test, done) ->
  Nav.setLocation '/back'
  Nav.setLocation '/forward'

  setTimeout (->
    test.isUndefined Nav.state
    test.equal Nav.location, '/forward'
    test.equal location.pathname, '/forward'
    Nav.back()
  ), delay

  setTimeout (->
    test.equal Nav.location, '/back'
    test.equal location.pathname, '/back'
    Nav.setLocation '/forward'
  ), delay * 2

  setTimeout (->
    Nav.back 2
  ), delay * 3

  setTimeout (->
    test.equal Nav.location, '/set/state'
    test.equal location.pathname, '/set/state'

    test.isNotNull Nav?.state, 'Nav.state should exist'
    test.isNotNull Nav?.state?.some, 'nav.state.some should exist'
    test.isNotNull Nav?.state?.another, 'nav.state.another should exist'

    test.equal Nav?.state?.some, 'value'
    test.equal Nav?.state?.another, 'value'

    done()
  ), delay * 4

Tinytest.addAsync 'forward()', (test, done) ->

  Nav.forward()

  setTimeout (->
    test.equal Nav.location, '/back'
    test.equal location.pathname, '/back'

    Nav.back()
  ), delay

  setTimeout (->
    test.equal Nav.location, '/set/state'
    test.equal location.pathname, '/set/state'

    Nav.forward 2
  ), delay * 2

  setTimeout (->
    test.equal Nav.location, '/forward'
    test.equal location.pathname, '/forward'
    reset()
    done()
  ), delay * 3

Tinytest.addAsync 'onLocation', (test, done) ->

  fn = (info) ->
    test.equal info.location, location1
    test.isNotNull info.computation, 'should have a computation'
    test.equal this, Nav
    test.equal this.location, location1
    setTimeout (-> done()), 50

  Nav.onLocation fn
  Nav.setLocation location1
