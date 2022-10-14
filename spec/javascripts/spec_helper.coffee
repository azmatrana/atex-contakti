#= require chai-backbone
#= require chai-jq
#= require chai-jquery
#= require ./support/factories
#= require twitter/bootstrap/modal
#= require user_dashboard/service
#= require i18n
#= require i18n/translations
#= require_self

mocha.ui('bdd')
mocha.ignoreLeaks()
mocha.timeout(5)
chai.config.includeStack = true
window.expect = chai.expect

beforeEach ->
  @page = $("#konacha")
  @sandbox = sinon.sandbox.create()
  @clock = sinon.useFakeTimers()
  @server = sinon.fakeServer.create()
  @server.autoRespond = true

afterEach ->
  @sandbox.restore()
  @clock.restore()

window.SpecHelper =
  taskGeneralBeforeEach: ->
    window.UserDashboard = {
      'tasksJSON': []
      'messagesJSON': []
    }
    @model = UserDashboardApp.currentTask = new UserDashboardApp.Models.CurrentTask()
    UserDashboardApp.tasksListSortFilter = new UserDashboardApp.Models.TaskSortFilter()
    @task = new UserDashboardApp.Models.Task(FactoryGirl.create('task').toJSON())
    @message = new UserDashboardApp.Models.Message(FactoryGirl.create('message', task_id: @task.id, number: 1, from: 'testovich@example.com').toJSON())
    @serviceChannel = FactoryGirl.create('service_channel', name: 'Service1', id: 1).toJSON()
    @serviceChannel2 = FactoryGirl.create('service_channel', name: 'Service2', id: 2).toJSON()
    @task.set('service_channel', @serviceChannel)
    @task.set('service_channel_id', @serviceChannel.id)
    @task.messages.push(@message)
    @currentTime = moment('2014-12-12 12:12:12')
    @task.set('created_at', @currentTime.format())
    @collection = new Backbone.Collection()
    UserDashboardApp.tasks = @collection
    UserDashboard.currentUserId = 1
