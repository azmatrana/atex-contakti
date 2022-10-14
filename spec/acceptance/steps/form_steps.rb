module FormSteps

  step 'I fill :field_name with :field_value' do |field_name, field_value|
    fill_in field_name, with: field_value
  end

  step 'I press :button' do |button|
    click_on button
  end

  step 'I fill (in) :field within :container with :value' do |field, container, value|
    within container do
      fill_in field, with: value
    end
  end

  step 'I select :value from :dropdown' do |value, dropdown|
    select value, from: dropdown
  end

  step 'I check :value' do |value|
    check value, visible: false
  end
end
