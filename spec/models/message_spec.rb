# == Schema Information
#
# Table name: messages
#
#  id             :uuid             not null, primary key
#  number         :integer          default(1), not null
#  from           :string(250)      default(""), not null
#  to             :string(250)      default(""), not null
#  title          :string(250)      default(""), not null
#  description    :text             default(""), not null
#  message_uid    :integer
#  in_reply_to_id :uuid
#  task_id        :integer
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#  is_internal    :boolean          default(FALSE), not null
#  sms            :boolean          default(FALSE), not null
#  channel_type   :string(20)       default("email"), not null
#  deleted_at     :datetime
#
# Indexes
#
#  index_messages_on_deleted_at  (deleted_at)
#

require 'rails_helper'

describe Message do
  it { should belong_to(:task) }
  it { should belong_to(:user) }
  it { should have_many(:attachments).class_name('Message::Attachment') }
  it { should validate_presence_of(:to) }
  it { should validate_inclusion_of(:channel_type).in_array(%w(email web_form call)) }

  context 'need_send_reply == 1' do
    before :each do
      subject.need_send_reply = 1
    end
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:title) }
  end

  context 'sms == true' do
    before :each do
      subject.sms = true
    end
    it { is_expected.to allow_value('+358401234567').for(:to) }
    it { is_expected.to allow_value('+380661234567').for(:to) }
    it { is_expected.to allow_value('+46723895601').for(:to) }
    it { is_expected.to_not allow_value('0401234567').for(:to) }
  end

  context 'instance methods' do
    let(:company) { ::FactoryGirl.create(:company) }
    let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
    let(:media_channel) { ::FactoryGirl.create(:media_channel_email, service_channel: service_channel) }
    let(:task) { ::FactoryGirl.create(:task, service_channel: service_channel, media_channel: media_channel) }
    subject { ::FactoryGirl.build :message, from: 'User Userovich <user.userovich@gmail.com>', task: task }

    context '#from_email' do
      it 'should return email if "from" field contains full name' do
        expect(subject.from_email).to eq('user.userovich@gmail.com')
      end

      it 'should return email if "from" field contains email only' do
        test_from    = 'test@blacorp.com'
        subject.from = test_from
        expect(subject.from_email).to eq(test_from)
      end
    end
    context '#push_message_to_browser' do
      subject { ::FactoryGirl.build :message, task: task }
      it 'should enqueue background job' do
        subject.push_message_to_browser
        expect(::DanthesPushWorker).to have_enqueued_job(subject.class.name, subject.id)
      end
    end

    context '#update_description!' do
      context 'if first message' do
        before :each do
          subject.number = 1
        end
        it 'should not call get_signature' do
          expect(subject).to_not receive(:get_signature)
          subject.update_description!
        end
        it 'should return true' do
          expect(subject.update_description!).to be_truthy
        end
      end
      context 'if internal message' do
        before :each do
          subject.number      = 2
          subject.is_internal = true
        end
        it 'should not call get_signature' do
          expect(subject).to_not receive(:get_signature)
          subject.update_description!
        end
        it 'should return true' do
          expect(subject.update_description!).to be_truthy
        end
      end
      context 'if sms message' do
        before :each do
          subject.number = 2
          subject.sms = true
          subject.to = '+380661234567'
        end
        it 'should not call get_signature' do
          expect(subject).to_not receive(:get_signature)
          subject.update_description!
        end
        it 'should return true' do
          expect(subject.update_description!).to be_truthy
        end
      end
      context 'if not first message, not sms and not internal message' do
        before :each do
          subject.number      = 2
          subject.sms         = false
          subject.is_internal = false
          subject.description = 'foo'
        end
        it 'should call get_signature' do
          expect(subject).to receive(:get_signature).and_call_original
          subject.update_description!
        end
        it 'should return true' do
          expect(subject.update_description!).to be_truthy
        end
        it 'should update description' do
          expect(subject.description).to eq('foo')
          allow(subject).to receive(:get_signature).and_return('bar')
          subject.update_description!
          expect(subject.description).to eq('foobar')
        end
      end
    end
  end


  context 'callbacks' do
    context 'after_commit', with_after_commit: true do
      subject { ::FactoryGirl.build :message }
      context 'on create' do
        context 'push_message_to_browser_on_create' do
          it 'should be called' do
            expect(subject).to receive(:push_message_to_browser_on_create)
            subject.save!
          end
          it 'should be not called' do
            subject.need_send_reply = 1
            expect(subject).to_not receive(:push_message_to_browser_on_create)
            subject.save!
          end
        end
        context 'push_message_on_queue_on_create' do
          it 'should be called with sms' do
            subject.sms = true
            subject.to  = '+380661234567'
            expect(subject).to receive(:push_message_on_queue_on_create)
            subject.save!
          end
          it 'should be called with internal message' do
            subject.is_internal = true
            expect(subject).to receive(:push_message_on_queue_on_create)
            subject.save!
          end
          it 'should not be called for reply' do
            subject.is_internal = false
            subject.sms         = false
            expect(subject).to_not receive(:push_message_on_queue_on_create)
            subject.save!
          end
        end
      end
      context 'on update' do
        context 'after_commit' do
          subject { ::FactoryGirl.build :message }
          context 'push_message_on_queue_on_update' do
            context 'if need_send_reply == 1' do
              before :each do
                subject.need_send_reply = 1
              end
              it 'should not be called with sms' do
                subject.sms = true
                subject.to  = '+380661234567'
                subject.save!
                subject.description = subject.description + 'blablabla'
                expect(subject).to_not receive(:push_message_on_queue_on_update)
                subject.save!
              end
              it 'should be called with internal message' do
                subject.is_internal = true
                subject.save!
                subject.description = subject.description + 'blablabla'
                expect(subject).to_not receive(:push_message_on_queue_on_update)
                subject.save!
              end
              it 'should be called for reply' do
                subject.is_internal = false
                subject.sms         = false
                subject.save!
                subject.description = subject.description + 'blablabla'
                expect(subject).to receive(:push_message_on_queue_on_update)
                subject.save!
              end
            end
            context 'if need_send_reply not set' do
              it 'should not be called with sms' do
                subject.sms = true
                subject.to  = '+380661234567'
                subject.save!
                subject.description = subject.description + 'blablabla'
                expect(subject).to_not receive(:push_message_on_queue_on_update)
                subject.save!
              end
              it 'should be called with internal message' do
                subject.is_internal = true
                subject.save!
                subject.description = subject.description + 'blablabla'
                expect(subject).to_not receive(:push_message_on_queue_on_update)
                subject.save!
              end
              it 'should be called for reply' do
                subject.is_internal = false
                subject.sms         = false
                subject.save!
                subject.description = subject.description + 'blablabla'
                expect(subject).to_not receive(:push_message_on_queue_on_update)
                subject.save!
              end
            end
          end
          context 'push_message_to_browser_on_update' do
            it 'should be called' do
              subject.save!
              subject.description = subject.description + 'blablabla'
              expect(subject).to receive(:push_message_to_browser_on_update)
              subject.save!
            end
            it 'should be not called' do
              subject.save!
              subject.description     = subject.description + 'blablabla'
              subject.need_send_reply = 1
              expect(subject).to_not receive(:push_message_to_browser_on_update)
              subject.save!
            end
          end
        end
      end
    end
  end

end
