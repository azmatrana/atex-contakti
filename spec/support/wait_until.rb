require 'timeout'
module WaitUntil
  def wait_until
    Timeout.timeout(Capybara.default_wait_time) do
      sleep(0.1) until value = yield
      value
    end
  end
end