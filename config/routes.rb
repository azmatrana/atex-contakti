Netdesk::Application.routes.draw do
  require 'sidekiq/web'
  # require 'sidekiq/cron/web'
  mount Sidekiq::Web => '/sidekiq'

  devise_for :super_admins, controllers: { sessions: "super_ui/sessions" }
  devise_for :users, path: '', path_names: {sign_in: 'login'}, controllers: { sessions: 'sessions', passwords: 'passwords' }

  get 'change_user/back' => 'sign_in_as#back'
  get 'change_user/:user_id' => 'sign_in_as#sign_in_as'

  namespace :super_ui do
    get '/' => 'companies#index'
    get '/details' => 'details#edit'
    post '/details' => 'details#update'
    resource :credentials, only: %i[edit]
    namespace :credentials do
      resource :fonnecta, only: %i[update]
      resource :tavoittaja, only: %i[update], controller: :tavoittaja
    end
    resources :admins
    resources :companies do
      member do
        post 'activate'
        delete 'deactivate'
        match 'billing', via: [:get, :post]
      end
    end
    resources :managers
    get '/switch_user/:id' => 'users#switch_user', as: 'switch_user'
    delete 'delete_service_tasks/:id', :to => 'admins#delete_service_tasks', as: 'delete-service-tasks'
  end

  get '/attachments/:message_id/:attachment_id' => 'attachments#show'
  get '/attachments/:task_id' => "attachments#note_attachment"
  get '/attachments/download_note_attachment/:note_id/:attachment_id' => "attachments#download_note_attachment"
  delete '/attachments/:id' => "attachments#destroy"

  scope "(:locale)", :locale => /en|fi|sv/ do
    root :to => "tasks#index"

    resource :sms, only: [:create]
    resource :sms_individual, only: [:create]
    resources :customers, only: %i[show create update destroy] do
      collection do
        post  :search_by_phone
      end
      member do
        put :update_task_note
        put :update_ready_task_note
      end
    end
    # Tasks
    resources :tasks, only: [:index, :update, :create, :destroy, :create_sms_template] do
      collection do
        get :search
        get :super_search
        get 'danthes/:channel_id' => 'tasks#danthes_subscribe'
        get 'danthes_bulk/bulk_subscribe' => 'tasks#danthes_bulk_subscribe'
        get 'subscribe_agents' => 'tasks#subscribe_agents'
        get :get_tasks
        get :get_ready_tasks
        get :call_history
        get :get_customer_tasks
        get :get_customer_ready_tasks
        get :get_task_by_id
        get :search_agents
        get :get_agents_by_service_channel_id
        get :get_all_service_channels
        post :add_call_history
        post :send_email
        post :send_chat_history
        post 'create_sms_template' => 'tasks#create_sms_template'
        put 'subscribe_to_agents_in_call_status'
        put 'change_in_call_status'
        get 'get_all_agents'
      end
      resources :messages, only: [:index, :show] do
        member do
          get ':oid' => :attachment, as: 'attachment'
        end
      end
      member do
        post :note
        post :change_state
        post :refresh_waiting_timeout
        post :change_service_channel
        post :assign_to_agent
        post :manage
        post :save_draft
        post :follow_task
        post :unfollow_task
        get :mark_message_as_read
      end
    end

    post 'login' => 'users#login'
    post 'users/send_reset_password_token'

    get 'details' => 'users#details'
    patch 'details' => 'users#update'
    # get 'details/get_details_kimai', :to => 'users#get_details_kimai'
    # post 'details/create_kimai_detail', :to => 'users#create_kimai_detail'
    post 'details/create_kimai_detail', :to => 'users#create_kimai_detail'
    # patch 'details/create_kimai_detail', :to => 'users#create_kimai_detail'


    resources :agents, except: :edit do
      collection do
        post 'search'
      end
      member do
        get 'filter_message'
        get 'render_activity_report'
        post 'create_skills'
        delete 'destroy_skills'
      end
    end
    put 'users/change_online_status'
    post 'users/update_kimai_credentials'
    post 'users/mark_as_seen'
    get 'set_locales/:locale' => "users#set_locales", as: "set_user_locale"

    resources :locations, except: :edit do
      collection do
        post 'search'
      end
    end

    resources :contacts do
      collection do
        post :upload_csv
        get  :search
        get  :public_phonebook
        delete  :delete_all
      end
    end

    resources :company_files
    
    post "cart_email_templates/create_update_order_placed_template"
    post "cart_email_templates/create_update_payment_link_template"
    post "cart_email_templates/create_update_terms_and_conditions_template"
    get "cart_email_templates/get_order_placed_template"
    get "cart_email_templates/get_order_payment_link_template"
    get "cart_email_templates/get_order_terms_and_conditions_template"

    resources :campaigns do
      collection do
        post :upload_csv
        get  :search
        delete  :delete_all

        get :download_template
      end

      resources :campaign_items do
        collection do
          get  :search
          get 'danthes_subscribe'
          delete  :delete_all
        end
      end
    end
    namespace :chatbot do
      resources :product_images
      resources :products do
        member do
          post :upload_attachments
        end
        collection do
          get :get_company_vats_and_currency
        end
      end
    end
    resources :questions
    resources :answers do
      collection do
        post :create_or_update
      end
    end
    resources :intents
    resources :template_replies
    resources :basic_templates
    resources :entities
    resources :synonyms
    resources :question_templates do
      collection do
        delete :destroy_all
        get :subscribe_to_danthes
        post :create_question_from_template
      end
    end
    resources :third_party_tools, only: [:create, :update, :destroy, :index]

    resources :shipment_methods

    resources :tags do
      collection do
        get 'download_template_file'
        get 'download_phonebook_template_file'
        get 'download_campaign_template_file'
        get 'create_kimai_detail'
        post 'create_skills'
        post 'upload_contacts'
        delete 'destroy_skills'
        delete 'cleanup'
        put 'set_priority'
        put :update_alarm_receivers
        put :update_email_template
        put :update_sms_template
        post 'create_kimai_detail'
        post 'save_kimai_url'
      end
      member do
        put 'select_time'
      end
    end

    resources :service_channels, only: [:index, :new, :show, :update, :destroy] do
      collection do
        post 'search'
        post 'test_imap_settings'
        post 'test_smtp_settings'
      end
      member do
        post 'create_skills'
        delete 'destroy_skills'
        delete 'delete_service_tasks'
      end
    end
    post 'service_channels' => 'service_channels#update'

    # reports
    resources :reports, only: [:index, :new, :destroy]
    get 'main_dashboard' => 'reports#dashboard', as: 'main_dashboard'
    post 'reports' => 'reports#save'
    get 'reports/:id/show' => 'reports#show', as: 'show_report'
    get 'reports/:id/edit' => 'reports#edit'
    get 'reports/:id/preview' => 'reports#show_preview', as: 'preview'
    get 'reports/:id/print' => 'reports#print'
    post 'reports/:id/send' => 'reports#send_report'
    get 'reports/:id' => 'reports#index', as: 'edit_report'
    post 'reports/search' => 'reports#search'
    patch 'reports/:id' => 'reports#save'
    post 'reports/:id' => 'reports#save'
    put 'reports/:id' => 'reports#update'
    put 'reports' => 'reports#update'

    post 'sms_receiver' => 'tavoittaja_inbound_sms#create'

    #dashboard( or report) layouts
    resources :dashboard_layouts do
      collection do
        get 'default'
      end
    end

    resources :users do
      member do
        get 'danthes_subscribe_user_online'
      end
    end
    resources :imap_settings
    resources :sms_templates
    delete 'sms_templates' => 'sms_templates#destroy'

    resources :vats, :only => [:create, :update, :destroy]
  end

  resources :call_detail_records, only: [:create] do
    collection do
      post 'json' => 'call_detail_records#create_from_json'
    end
  end

  get 'sip_widget/test/:id' => 'sip_widget#test'
  resources :sip_widget, :only => [:show], :defaults => { :format => 'js' }

  # This is where chat client bootstrap js is loaded.
  # Also agent requests can go through here.
  # Client needs to communicate via api because CORS
  # Chat stuff is embedded in the target site with:
  # <script src="https://localhost:3001/chat/123"></script>
  #  where 123 is the chat media_channel_id
  get '/build_plugin'      => "chat#build_plugin"

  resources :chat, :only => [:show, :update], :defaults => { :format => 'js' } do
    member do
      get 'control' => 'chat#subscribe_to_control'
      post 'control' => 'chat#relay_control_message'
      get 'join'
      post 'send_msg'
      get 'log'
      post 'rate'
      post 'send_indicator'
    end
    collection do
      get 'get_vehicle_data'
    end
  end

  get '/paytrail_payments/success'
  get '/paytrail_payments/failure'
  get '/paytrail_payments/notification'

  namespace :api, :defaults => {:format => :json} do
    namespace :v1 do
      match '*path' => 'base#cors_preflight_check',
            :via => [:options],
            :constraints => {:method => 'OPTIONS'}

      resources :users, only: [:index, :update] do
        collection do
          get 'recepient_emails'
        end
      end
      resources :tasks, only: [:index, :create, :update, :destroy] do
        collection do
          post 'create_task_from_chat'
          post 'send_email'
          get 'ready_tasks' => 'tasks#get_ready_tasks'
          get 'danthes/:channel_id' => 'tasks#danthes_subscribe'
          get 'danthes_bulk/bulk_subscribe' => 'tasks#danthes_bulk_subscribe'
        end
        member do
          post 'reply'
          post 'note'
          post 'change_task_state'
        end

        resources :messages, only: [:index]
      end

      resources :agent_call_logs, only: [:index, :create, :update] do
        collection do
          get 'danthes_subscribe'
          post 'destroy_all'
          post 'user_call_settings'# => "agent_call_logs#user_call_settings"
        end
      end

      resources :sms_templates, only: [:index]
      resources :service_channels, only: [:index]
      resources :media_channels, only: [:index]

      get    '/tags'              => "tags#index"
      post   '/tags'              => "tags#create"
      delete '/tags'              => "tags#destroy"
      put    '/tags'              => "tags#update"
      get    '/tags/company'      => "tags#company"
      post   '/tags/task_skills'  => "tags#add_task_skills"
      get    '/users/get_kimai_detail' => "users#get_kimai_detail"
      post "create_tracker_detail" => 'tracker_detail#create_tracker_detail'
      get "get_tracker_detail" => 'tracker_detail#get_tracker_detail'
      post "create_kimai_detail" => 'kimai_detail#create_kimai_detail'

      resources :sessions, only: [:create, :destroy] do
        collection do
          get 'check'
        end
      end

      resources :chat do
        member do
          post  'initiate_chat'
          post  'bot_initiate_human_chat'
          get  'abort_chat'
          post 'send_msg'
          post 'create_callback'
          post 'send_email_chat_history'
          post 'send_indicator'
          get 'get_chat_settings'
        end

        collection do
          get 'get_translations'
          get 'set_client_connected'
          get 'has_client_left'
          get 'set_client_info'
          post 'uploadfile'
          post 'send_quit'
        end
      end
      resources :orders, only: [:create, :show]
      resources :customers, only: [:create]

    end
  end

end
