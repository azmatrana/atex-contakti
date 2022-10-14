class Entity < ActiveRecord::Base
  belongs_to :company
  # has_many :key_words, dependent: :destroy
  validates :name, presence: true
  validates_uniqueness_of :name, scope: :company_id, :case_sensitive => false
  after_create :create_at_wit
  after_update :send_to_wit
  before_destroy :delete_from_wit

  def create_at_wit
    wit_service = WitService.new(self.company)
    begin
      res = wit_service.create_entity_at_wit(self)
      self.update_column("name", res["name"])
      self.update_column("key_words", res["keywords"])
      puts res
    rescue => e
      if e.code && e.code == "already-exists"
        raise "#{I18n.t('activerecord.attributes.entity.name')} #{I18n.t('errors.messages.taken')}"
      else
        raise e.message
      end
    end

  end

  def send_to_wit
    wit_service = WitService.new(self.company)
    res = wit_service.send_entity_to_wit(self)
    self.update_column("name", res["name"])
    self.update_column("key_words", res["keywords"])
    puts res
  end

  def delete_from_wit
    wit_service = WitService.new(self.company)
    res = wit_service.delete_entities_from_wit(self.name)
    res
  end


end
