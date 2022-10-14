class Chatbot::ProductImage < ActiveRecord::Base
   self.table_name = "product_images"
   belongs_to :chatbot_product, :class_name => 'Chatbot::Product'
  mount_uploader :file, ImageUploader
  validates :file, presence: true
  after_destroy do
    self.remove_file
  end
   before_save :set_file_details, on: :create

  def set_file_details
    self.file_name = self.file.identifier
    self.file_type = self.file.content_type.split("/")[1]
    self.file_size = self.file.size
  end

end
