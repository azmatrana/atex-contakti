class CustomerTaskSerializer < TaskSerializer
  has_many :messages, serializer: ExtendMessageSerializer
end
