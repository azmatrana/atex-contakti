# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( init.js user_dashboard.js danthes.js better_user_dashboard/*
  chat_client/* chat_client.css ie8.css firefox.css libs.css fonts.css sip/sip_widget.js admin_view_modals.js )
