require 'rails_helper'

RSpec.describe MessagesController, :type => :controller do
  let(:company) { ::FactoryGirl.create :company }
  let(:user) { ::FactoryGirl.create :agent, company: company }
  let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
  let(:task) { ::FactoryGirl.create :task, state: 'open', service_channel: service_channel }
  let(:message) { ::FactoryGirl.create :message, user: user, task: task }
  let(:another_company) { ::FactoryGirl.create :company }
  let(:another_service_channel) { ::FactoryGirl.create :service_channel, company: another_company }
  let(:another_task) { ::FactoryGirl.create(:task_with_messages, service_channel: another_service_channel) }

  before(:each) do
    allow(::I18n).to receive(:locale).and_return(:en)
    sign_in(user)
    message
  end

  context 'task is acceptable for user' do
    before :each do
      task.assigned_to_user_id = user.id
      task.save!
    end

    describe "GET index" do
      it "returns http success" do
        get :index, task_id: task.id
        expect(response).to be_success
      end

      it "returns http redirect" do
        get :index, task_id: another_task.id
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).not_to be_empty
      end
    end

    describe "GET show" do
      it "returns http success" do
        get :show, task_id: task.id, id: task.messages.first.id
        expect(response).to be_success
      end
      it "returns http redirect" do
        get :show, task_id: another_task.id, id: another_task.messages.first.id
        expect(assigns[:message]).to be_nil
        expect(response).to have_http_status(302)
        expect(flash[:alert]).not_to be_empty
      end
    end

    describe "GET attachment" do
      it "returns http success" do
        attachment = ::FactoryGirl.create(:message_attachment, message: message)
        get :attachment, task_id: task.id, id: task.messages.first.id, oid: attachment.id
        expect(response).to be_success
      end
    end
  end
end
