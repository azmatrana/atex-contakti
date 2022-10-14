class ExtendedTaskSerializer < TaskSerializer
  has_many :messages

  def messages
    object.messages.reverse
  end
end
