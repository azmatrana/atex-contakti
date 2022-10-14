class AddUseContaktiSmtpInSmtp < ActiveRecord::Migration
  def change
    add_column :smtp_settings, :use_contakti_smtp, :boolean, default: false
  end
end
