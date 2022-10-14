class CallTranslatorWorker
  include ::Sidekiq::Worker
  sidekiq_options retry: true

  def perform(message_id)
    message = Message.where(id: message_id).first
    return true if message.blank?
    return true if message.call_recording_attachment.blank?
    return true if !message.task.company.allow_call_translation?

    translator = ::ContaktiCDR::Transcripts.new(message.id)
    translator.fetch_and_populate_tranlations
  end
end
