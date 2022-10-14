module EmailHelpers
  def fetch_email(imap_instance, path, fetch_result)
    email_body = ::File.open(path, 'rb') { |f| f.read }
    expect(imap_instance).to receive(:fetch).with('message_uuid', '(UID RFC822)').and_return([fetch_result])
    allow(fetch_result).to receive(:attr).and_return({'UUID' => 'UUID', 'RFC822' => email_body})
  end
end

RSpec.configure do |config|
  config.include EmailHelpers
end
