# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
I18n.available_locales = [:en, :fi, :sv]
Rails.application.config.i18n.default_locale = :en
