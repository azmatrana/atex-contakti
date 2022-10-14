require 'delorean'
RSpec.configure do |config|
  config.include Delorean
  config.after(:each) do
    back_to_the_present
  end
end
