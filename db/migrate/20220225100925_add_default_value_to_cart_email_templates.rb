class AddDefaultValueToCartEmailTemplates < ActiveRecord::Migration
  def change
    Company.all.each do |company|
      if company.cart_email_templates.where(template_for: "order_placed").count == 0
        company.cart_email_templates.create({ template_for: "order_placed", subject: I18n.translate('tags.order_placed'), body: "{{products}}" })
      end
      if company.cart_email_templates.where(template_for: "order_payment_link").count == 0
        company.cart_email_templates.create({ template_for: "order_payment_link", subject: I18n.translate('tags.payment_link'), body: "{{payment_link}}" })
      end
      if company.cart_email_templates.where(template_for: "terms_and_conditions").count == 0
        company.cart_email_templates.create({ template_for: "terms_and_conditions", subject: I18n.translate('tags.terms_and_conditions'), body: I18n.translate('tags.terms_and_conditions') })
      end
    end
  end
end
