class CartEmailTemplate < ActiveRecord::Base
  belongs_to :company
  validates_presence_of :subject, :body

  def self.get_order_placed_template
    find_by_template_for("order_placed")
  end

  def self.get_payment_link_template
    find_by_template_for("order_payment_link")
  end
end
