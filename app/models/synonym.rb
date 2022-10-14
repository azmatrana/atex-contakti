class Synonym < ActiveRecord::Base
  belongs_to :company
  belongs_to :key_word
end