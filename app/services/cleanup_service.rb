class CleanupService

  def last_time
    @last_time ||= ::Time.current.advance(days: -30)
  end

  def broken_media_channels
    @broken_media_channels ||= begin
      mc_table = ::MediaChannel.arel_table
      ::MediaChannel.where(
        mc_table[:broken].eq(true).and(
          mc_table[:updated_at].lt(last_time)
        )
      ).select(:id).ast
    end
  end

  def tasks
    @tasks ||= begin
      task_table  = ::Task.arel_table
      closed_sql  = task_table[:state].eq('ready').and(
        task_table[:updated_at].lt(last_time)
      ).to_sql
      deleted_sql = task_table[:deleted_at].lt(last_time).to_sql
      broken_media_channels_sql = task_table[:media_channel_id].in(broken_media_channels).to_sql
      ::Task.unscoped.where("(#{closed_sql}) OR (#{deleted_sql}) OR (#{broken_media_channels_sql})")
    end
  end

  def run
    tasks.includes(messages: [:attachments]).find_each do |task|
      task.messages.each do |message|
        message.attachments.each do |attachment|
          attachment.remove_file!
        end
        message.attachments.delete_all
      end
      task.messages.delete_all
      task.without_versioning :really_destroy!
    end
    ::ServiceChannel.only_deleted.where('deleted_at < ?', last_time).find_each do |service_channel|
      service_channel.really_destroy!
    end
  end
end
