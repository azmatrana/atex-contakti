#= require spec_helper

describe 'UserDashboardApp', ->
  describe 'Models', ->
    describe 'Task', ->

      it 'should be extends from Backbone.Model', ->
        expect(UserDashboardApp.Models.Task.__super__.constructor).to.eq(Backbone.Model)

      describe 'initialize', ->
        it 'should call @initMessages', ->
          @sandbox.spy(UserDashboardApp.Models.Task.prototype, 'initMessages')
          new UserDashboardApp.Models.Task()
          expect(UserDashboardApp.Models.Task.prototype.initMessages).to.have.been.called

        it 'should call @setLastMessage', ->
          @sandbox.spy(UserDashboardApp.Models.Task.prototype, 'setLastMessage')
          new UserDashboardApp.Models.Task()
          expect(UserDashboardApp.Models.Task.prototype.setLastMessage).to.have.been.called

        it 'should call @setFirstMessage', ->
          @sandbox.spy(UserDashboardApp.Models.Task.prototype, 'setFirstMessage')
          new UserDashboardApp.Models.Task()
          expect(UserDashboardApp.Models.Task.prototype.setFirstMessage).to.have.been.called

        it 'should call @setLastMessage on changing last_message_at', ->
          @sandbox.spy(UserDashboardApp.Models.Task.prototype, 'setLastMessage')
          task = new UserDashboardApp.Models.Task()
          task.set('last_message_at', new Date())
          expect(UserDashboardApp.Models.Task.prototype.setLastMessage).to.have.been.called

        it 'should call @updateFirstLastMessage on @message add and remove events', ->
          @sandbox.spy(UserDashboardApp.Models.Task.prototype, 'updateFirstLastMessage')
          task = new UserDashboardApp.Models.Task()
          task.messages.push({a:'b', c: 'd'})
          expect(UserDashboardApp.Models.Task.prototype.updateFirstLastMessage).to.have.been.called

        it 'should call @updateFirstLastMessage on @message remove event', ->
          @sandbox.spy(UserDashboardApp.Models.Task.prototype, 'updateFirstLastMessage')
          task = new UserDashboardApp.Models.Task({id: 1, messages: [{'a' : 'b', 'c' : 'd'}]})
          task.messages.pop()
          expect(UserDashboardApp.Models.Task.prototype.updateFirstLastMessage).to.have.been.called

      describe 'instance', ->
        beforeEach ->
          @message1 = FactoryGirl.create('message', task_id: 12, number: 1).toJSON()
          @message2 = FactoryGirl.create('message', task_id: 13).toJSON()
          @clock.tick(10000)
          @message3 = FactoryGirl.create('message', task_id: 12).toJSON()

        describe 'messages', ->
          it 'should be instance of UserDashboardApp.Collections.Messages', ->
            task = new UserDashboardApp.Models.Task({id: 12})
            expect(task.messages).to.be.instanceof(UserDashboardApp.Collections.RawMessages)

        describe 'initMessages', ->
          it 'should create new UserDashboardApp.Collections.RawMessages collection', ->
            rawMessages = new UserDashboardApp.Collections.RawMessages()
            mySpy = @sandbox.spy(rawMessages.__proto__, 'initialize')
            new UserDashboardApp.Models.Task({id: 12, messages: [@message1]})
            expect(mySpy).to.have.been.calledWith([@message1], {url: '/tasks/12/messages'})

          it 'should init @messages properly', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: [@message1, @message3]})
            expect(task.messages.length).to.eq(2)
            expect(task.messages.at(0).id).to.eq(@message1.id)
            expect(task.messages.at(1).id).to.eq(@message3.id)

        describe 'setLastMessage', ->
          it 'should set last message', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: [@message1, @message3]})
            expect(task.get('lastMessage').id).to.eq(@message3.id)

          it 'should not set last message if no messages', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: []})
            expect(task.get('lastMessage')).to.eq(undefined)

          it 'should set last message to the same as first message', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: [@message1, @message2]})
            expect(task.get('lastMessage').id).to.eq(task.get('firstMessage').id)

        describe 'setFirstMessage', ->
          it 'should set first message', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: [@message1, @message3]})
            expect(task.get('firstMessage').id).to.eq(@message1.id)

          it 'should not set first message if messages is empty', ->
            task = new UserDashboardApp.Models.Task({id: 12})
            expect(task.get('firstMessage')).to.eq(undefined)

        describe 'internalMessages()', ->
          it 'should be instance of UserDashboardApp.Collections.Messages', ->
            task = new UserDashboardApp.Models.Task({id: 12})
            expect(task.internalMessages()).to.be.instanceof(UserDashboardApp.Collections.Messages)

          it 'should return collection with internal messages', ->
            message4 = FactoryGirl.create('message', task_id: 12, is_internal: true).toJSON()
            task = new UserDashboardApp.Models.Task({id: 12, messages: [@message1, @message3, message4]})
            expect(task.internalMessages().length).to.eq(1)
            expect(task.externalMessages().length).to.eq(2)

          it 'should return empty collection if no internal messages', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: []})
            expect(task.internalMessages().length).to.eq(0)

        describe 'externalMessages()', ->
          it 'should be instance of UserDashboardApp.Collections.Messages', ->
            task = new UserDashboardApp.Models.Task({id: 12})
            expect(task.externalMessages()).to.be.instanceof(UserDashboardApp.Collections.Messages)

          it 'should return empty collection if no external messages', ->
            task = new UserDashboardApp.Models.Task({id: 12})
            expect(task.externalMessages().length).to.eq(0)

          it 'should return collection with internal messages', ->
            task = new UserDashboardApp.Models.Task({id: 12, messages: [@message1, @message3]})
            expect(task.externalMessages().length).to.eq(2)
            expect(task.internalMessages().length).to.eq(0)

  describe 'Collections', ->
    describe 'RawTasks', ->
      it 'should have model set to Task', ->
        expect(UserDashboardApp.Collections.RawTasks.prototype).to.have.property('model', UserDashboardApp.Models.Task)

      it 'should be extends from Backbone.Collection', ->
        expect(UserDashboardApp.Collections.RawTasks.__super__.constructor).to.eq(Backbone.Collection)

    describe 'Tasks', ->
      it 'should be extends from VirtualCollection', ->
        expect(UserDashboardApp.Collections.Tasks.__super__.constructor).to.eq(VirtualCollection)

      describe 'countByState', ->
        it 'should return proper counters', ->
          window.UserDashboard = { messagesJSON: [] }
          collection = []
          collection.push({id: 1, state: 'new'})
          collection.push({id: 2, state: 'new'})
          collection.push({id: 3, state: 'new'})
          collection.push({id: 4, state: 'closed'})
          collection.push({id: 5, state: 'closed'})
          bCollection = new UserDashboardApp.Collections.RawTasks(collection)
          vCollection = new UserDashboardApp.Collections.Tasks(bCollection)
          expect(vCollection.countByState('closed')).to.eq(2)
          expect(vCollection.countByState('new')).to.eq(3)

