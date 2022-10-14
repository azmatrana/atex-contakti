module AgentSteps
  include Warden::Test::Helpers
  Warden.test_mode!

  step 'I should be on agent dashboard' do
    expect(current_path).to match ::Regexp.new("^/|/en$")
  end

  step 'agent exists' do
    @company ||= ::FactoryGirl.create :company
    @agent = ::FactoryGirl.create :agent, company: @company
  end

  step  'second agent exists' do
    @company ||= ::FactoryGirl.create :company
    @agent2 = ::FactoryGirl.create :agent, company: @company
  end

  step 'agent exists with email :email and password :password' do |email, password|
    @company ||= ::FactoryGirl.create :company
    @agent = ::FactoryGirl.create :agent, company: @company, email: email
    @agent.password = password
    @agent.save
  end

  step 'agent is logged in' do
    login_as(@agent, scope: :user)
  end

  step 'agent is manually logged in' do
    visit root_path
    step 'I fill "user[email]" with "bla@bla.com"'
    step 'I fill "user[password]" with "password"'
    step 'I press "Login"'
  end

  step 'agent is logged in with/via token' do
    token = 'test'
    @agent.update_attribute(:authentication_token, token)
    visit "/?email=#{@agent.email}&token=#{token}"
  end

  step 'I am on login page' do
    visit '/login'
  end

  step 'I am on agent dashboard page' do
    visit root_path
  end

  step 'agent is assigned to service channel' do
    @agent.service_channel_ids = [@service_channel.id]
  end

  step 'agent is assigned to all service channels' do
    @agent.service_channel_ids = ::ServiceChannel.all.map(&:id)
  end

  step 'there exists a :state :type task with title :title and text :text' do |state, type, title, text|
    media_channel_type = case type
                         when 'call' then 'call_media_channel'
                         when 'web_form' then 'web_form_media_channel'
                         else 'email_media_channel'
                         end
    task = ::FactoryGirl.create :task, state: state, service_channel: @service_channel, media_channel: @service_channel.__send__(media_channel_type)
    ::FactoryGirl.create :message, title: title, description: text, task: task
  end

  step 'all tasks is visible for agent' do
    @agent.task_ids = ::Task.pluck(:id)
  end

  step 'task with title :title is assigned to agent' do |title|
    task = ::Message.where(title: title).first.task
    task.update_attribute(:assigned_to_user_id, @agent.id)
  end

  step 'there exists a :state task with title :title and text :text' do |state, title, text|
    step %Q[there exists a "#{state}" email task with title "#{title}" and text "#{text}"]
  end

  step 'there exists a task with title :title and text :text' do |title, text|
    step %Q[there exists a new task with title "#{title}" and text "#{text}"]
  end

  step 'I select :value from task states dropdown' do |value|
    select(value, from: 'filter_task_by_state')
  end

  step 'I should see :n task(s)' do |n|
    tasks_number = all('table.task-item').length
    expect(tasks_number).to equal(n.to_i)
  end

  step 'I type :value in search form' do |value|
    search_box = find('#search_inbox')
    value.each_char do |c|
      search_box.native.send_keys c
      sleep 0.2
    end
  end

  step 'I click task titled :title' do |title|
    find('table.task-item h1.item-title', text: title).click
  end

  step 'I fill in reply form with :text' do |text|
    within('#reply-form-container') do
      fill_in 'reply[description]', with: text
    end
  end

  step '(the) task should have :n messages' do |n|
    @task ||= ::Task.last
    expect(@task.messages.count).to equal(n.to_i)
  end

  step '(the) task should have :n internal message(s)' do |n|
    @task ||= ::Task.last
    expect(@task.messages.where(is_internal: true).count).to equal(n.to_i)
  end

  step '(the) task should have :n sms/SMS message(s)' do |n|
    @task ||= ::Task.last
    expect(@task.messages.where(sms: true).count).to equal(n.to_i)
  end

  step '(the) task should belong to (the) service channel :name' do |name|
    @task ||= ::Task.last
    service_channel = ::ServiceChannel.where(name: name).first
    expect(@task.service_channel).to eq(service_channel)
  end

  step '(the) task state should be :state' do |state|
    @task ||= ::Task.last
    @task.reload
    expect(@task.state).to eq(state)
  end

  step "default agent's dashboard" do
    step %Q(agent exists with email "bla@bla.com" and password "password")
    step %Q(there exists service channel with name "Test service channel")
    step %Q(there exists service channel with name "Another service channel")
    step %Q(agent is assigned to all service channels)
    step %Q(agent is logged in)
  end

  step 'state changed to :state by second agent for task with title :title' do |state, title|
    task = ::Message.where(title: title).first.task
    task.state = state
    task.assigned_to_user_id = @agent2.id
    task.save!
  end

  step 'I choose :state state in bootbox dialog' do |state|
    within('#task-buttons-confirmation-form') do
      find('input[name="event"][value="' + state + '"]').click
    end
    within('div.bootbox') do
      find('button[data-bb-handler="success"]').click
    end
  end

  step 'I should see bootbox alert what task in use' do
    expect(page.has_selector?('div.bootbox-alert')).to be_truthy
    expect(page).to have_text(::I18n.t('user_dashboard.task_is_already_in_work', agent: @agent2.decorate.full_name))
    within('div.bootbox') do
      find('button.btn-primary').click
    end
  end

end
