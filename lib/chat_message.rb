
class ChatMessage

  def initialize(params)
    @from = params[:from]
    @type = params[:type]
    @channel_id = params[:channel_id]
    @message = params[:message]
    @file_path = params[:file_path]
    @files = params[:files]
    @custom_action_text = params[:custom_action_text]
    @has_custom_action = params[:has_custom_action]
    @action_buttons = params[:action_buttons]
    @products = params[:products]
    @images = params[:images]
    @timestamp = DateTime.now
    @attempts = params[:attempts]
  end

  def to_hash
    hash = {}
    instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    hash
  end



end
