class CompanyFile < ActiveRecord::Base
  belongs_to :company
  has_many :answer_company_files
  has_many :answers , through: :answer_company_files
  validates :file_name, uniqueness: true
  mount_uploader :file, CompanyFileUploader
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

  def humanize_file_size
    ::Helpers::FileSizeFormat.humanize(self.file_size)
  end

end
