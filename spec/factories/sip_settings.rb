FactoryGirl.define do
  factory :sip_settings do
    sequence :title do |num|
      "Sip setting $№ #{num}"
    end

    domain { FFaker::Internet.domain_name }
    user_name { FFaker::Internet.user_name }
    password 'password'
    ws_server_url { "ws://#{domain}/ws"}
  end
end
