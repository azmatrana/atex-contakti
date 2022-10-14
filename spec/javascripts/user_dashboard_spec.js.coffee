#= require spec_helper
#= require user_dashboard/app

suite = describe 'UserDashboardApp', ->

  before (done) ->
    for item, index in ['Models', 'Collections', 'Views', 'Routers']
      do (item, index) ->
        suite.addTest new Mocha.Test "creates #{item}", ->
          expect(UserDashboardApp[item]).to.exist
    done()

  it "creates a global variable with namespaces", ->
    expect(UserDashboardApp).to.exist
