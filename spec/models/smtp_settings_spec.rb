# == Schema Information
#
# Table name: smtp_settings
#
#  id          :integer          not null, primary key
#  server_name :string(100)      default(""), not null
#  user_name   :string(100)      default(""), not null
#  password    :string(100)      default(""), not null
#  description :text             default(""), not null
#  port        :integer          default(465), not null
#  use_ssl     :boolean          default(TRUE), not null
#  company_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#  auth_method :string(20)       default(""), not null
#

require 'spec_helper'

describe SmtpSettings do

  subject { ::FactoryGirl.create(:smtp_settings) }

  it 'should have a valid factory' do
    expect(::FactoryGirl.build :smtp_settings).to be_valid
  end

  context '#get_auth_method' do
    
    it 'should return correct auth method' do
      expect(subject.get_auth_method).to equal(:ntlm)
    end

    it 'should return login auth method if auth method is not set' do
      subject.auth_method = ''
      expect(subject.get_auth_method).to equal(:login)
    end

  end

end
