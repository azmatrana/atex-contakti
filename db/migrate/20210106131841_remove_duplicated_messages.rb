class RemoveDuplicatedMessages < ActiveRecord::Migration
  def up
    message_ids = ::Message.unscoped.map(&:id)
    message_ids.each do |message_id|
      message = ::Message.unscoped.where(id: message_id).first
      next unless message
      duplicated_messages = ::Message.unscoped.where(task_id: message.task_id, message_uid: message.message_uid).where.not(id: message.id)
      duplicated_messages.each do |duplicated_message|
        duplicated_message.really_destroy!
      end
    end
  end

  def down
    # do nothing
  end
end
