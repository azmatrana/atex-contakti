class ThirdPartyTool < ActiveRecord::Base
  belongs_to :company
  validates_presence_of :title
end