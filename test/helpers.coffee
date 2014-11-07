module.exports =
  asyncAssert: (done, assert) ->
    try
      assert()
      done()
    catch e
      done(e)