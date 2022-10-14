require 'pry'

step 'I wait for :n second(s)' do |n|
  sleep n.to_i
end

step 'I stop at breakpoint' do
  binding.pry
end

step 'I should see text :text' do |text|
  expect(page).to have_text(text)
end

step 'I should not see text :text' do |text|
  expect(page).not_to have_text(text)
end

step 'I click on text :value' do |value|
  find(value).click
end

step 'I click on :text (button)' do |text|
  all(:link_or_button, text: text, visible: true)[0].click
end

step 'I click on :button within :container' do |button, container|
  within container do
    click_on button
  end
end

step 'I should be on login page' do
  expect(current_path).to start_with(login_path)
end

step 'there exists service channel with name :name' do |name|
  @company ||= ::FactoryGirl.create :company
  @service_channel = ::FactoryGirl.create :service_channel, company: @company, name: name
end

step 'I should see an confirm notification' do
  expect(page.has_selector?('div.bootbox-confirm')).to be_truthy
end

step 'I should see a bootbox dialog' do
  expect(page.has_selector?('div.bootbox.modal[role="dialog"]')).to be_truthy
end

step 'I confirm notification' do
  find('button[data-bb-handler="confirm"]').click
end

step 'I wait until all Ajax requests are complete' do
  wait_until do
    page.evaluate_script('$.active').to_i == 0
  end
end

step 'push to browser is stubbed' do
  allow(Danthes).to receive(:publish_to)
end

step ':name background jobs finished' do |name|
  sleep 1
  if name && name != 'all'
    name.constantize.drain
  else
    Sidekiq::Worker.drain_all
  end
end