FactoryGirl.sequence 'task_id', (id) ->
  id

FactoryGirl.define 'task', ->
  @sequence('task_id', 'id')
  @state = 'new'
  @is_not_call = true
