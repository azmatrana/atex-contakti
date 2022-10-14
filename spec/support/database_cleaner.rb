RSpec.configure do |config|
  config.use_transactional_examples = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    use_truncation = example.metadata[:with_after_commit] || ::Capybara.current_driver == :poltergeist || ::Capybara.current_driver == :selenium
    DatabaseCleaner.strategy = use_truncation ? :truncation : :transaction
    DatabaseCleaner.start
  end
     
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
