# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20220805205218) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "agent_call_logs", force: true do |t|
    t.integer  "agent_id"
    t.string   "caller_name"
    t.string   "clid"
    t.string   "flow"
    t.string   "sip_id"
    t.string   "call_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uri"
    t.integer  "call_start",             limit: 8
    t.integer  "call_stop",              limit: 8
    t.integer  "callable_id"
    t.string   "callable_type"
    t.boolean  "visible",                          default: true
    t.integer  "call_ring_start"
    t.integer  "call_ring_stop"
    t.integer  "call_ring_wait_seconds"
    t.integer  "call_duration_seconds"
  end

  add_index "agent_call_logs", ["agent_id"], name: "index_agent_call_logs_on_agent_id", using: :btree
  add_index "agent_call_logs", ["callable_id", "callable_type"], name: "index_agent_call_logs_on_callable_id_and_callable_type", using: :btree

  create_table "agent_campaigns", force: true do |t|
    t.integer  "campaign_id"
    t.integer  "agent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "agent_campaigns", ["agent_id"], name: "index_agent_campaigns_on_agent_id", using: :btree
  add_index "agent_campaigns", ["campaign_id"], name: "index_agent_campaigns_on_campaign_id", using: :btree

  create_table "answer_buttons", force: true do |t|
    t.string   "text",                    null: false
    t.integer  "answer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hyper_link", default: ""
  end

  create_table "answer_company_files", force: true do |t|
    t.integer "answer_id"
    t.integer "company_file_id"
  end

  create_table "answer_images", force: true do |t|
    t.string   "file",       null: false
    t.string   "file_name",  null: false
    t.integer  "file_size"
    t.string   "file_type"
    t.integer  "answer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "answers", force: true do |t|
    t.text     "text"
    t.integer  "intent_id"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_file_id"
    t.string   "custom_action_text", default: ""
    t.boolean  "has_custom_action",  default: false
  end

  create_table "basic_templates", force: true do |t|
    t.string   "title",      null: false
    t.text     "text"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "call_histories", force: true do |t|
    t.string   "remote"
    t.boolean  "incoming"
    t.string   "duration"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "call_histories", ["user_id"], name: "index_call_histories_on_user_id", using: :btree

  create_table "campaign_items", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "email"
    t.string   "info_1"
    t.string   "address"
    t.string   "city"
    t.string   "country"
    t.string   "info_2"
    t.string   "postcode"
    t.integer  "campaign_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaign_items", ["campaign_id"], name: "index_campaign_items_on_campaign_id", using: :btree

  create_table "campaigns", force: true do |t|
    t.string   "name"
    t.integer  "company_id"
    t.integer  "service_channel_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaigns", ["company_id"], name: "index_campaigns_on_company_id", using: :btree
  add_index "campaigns", ["service_channel_id"], name: "index_campaigns_on_service_channel_id", using: :btree

  create_table "cart_email_templates", force: true do |t|
    t.integer  "company_id"
    t.string   "name"
    t.string   "subject"
    t.text     "body"
    t.string   "template_for"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chat_initial_buttons", force: true do |t|
    t.string  "title"
    t.integer "chat_settings_id"
  end

  create_table "chat_inquiry_fields", force: true do |t|
    t.string  "title"
    t.string  "input_type",       default: "text"
    t.integer "chat_settings_id"
  end

  create_table "chat_records", force: true do |t|
    t.string   "channel_id"
    t.datetime "answered_at"
    t.integer  "answered_by_user_id"
    t.integer  "service_channel_id"
    t.integer  "media_channel_id"
    t.datetime "ended_at"
    t.boolean  "user_quit"
    t.string   "result"
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "chat_records", ["answered_at"], name: "index_chat_records_on_answered_at", using: :btree
  add_index "chat_records", ["channel_id"], name: "index_chat_records_on_channel_id", using: :btree

  create_table "chat_settings", force: true do |t|
    t.text     "whitelisted_referers"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color",                        default: "#0dc0c0"
    t.text     "welcome_message",              default: "How can I help?"
    t.integer  "format",                       default: 0
    t.string   "file"
    t.string   "text_color",                   default: "#ffffff"
    t.boolean  "enable_chatbot",               default: false
    t.text     "initial_msg",                  default: ""
    t.string   "bot_alias"
    t.boolean  "enable_cart",                  default: false
    t.string   "chat_title",                   default: "Chat"
    t.boolean  "enable_initial_buttons",       default: true
    t.boolean  "checkout_paytrail",            default: false
    t.boolean  "checkout_ticket",              default: true
    t.string   "paytrail_payment_success_url"
    t.string   "paytrail_payment_failure_url"
  end

  create_table "chatbot_answer_products", force: true do |t|
    t.integer "answer_id"
    t.integer "product_id"
  end

  create_table "chatbot_customers", force: true do |t|
    t.string   "full_name"
    t.string   "email"
    t.string   "phone_number"
    t.string   "street_address"
    t.string   "city"
    t.string   "zip_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chatbot_order_products", force: true do |t|
    t.integer  "chatbot_order_id"
    t.integer  "chatbot_product_id"
    t.integer  "quantity"
    t.decimal  "price",              precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency",                                   default: "€"
    t.boolean  "with_vat",                                   default: false
    t.integer  "vat_percentage",                             default: 0
  end

  create_table "chatbot_orders", force: true do |t|
    t.string   "checkout_method"
    t.integer  "company_id"
    t.float    "total"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "task_id"
    t.text     "inquiry_fields_data",                         default: ""
    t.integer  "shipment_method_id"
    t.integer  "service_channel_id"
    t.text     "preferred_language",                          default: ""
    t.string   "currency",                                    default: "€"
    t.integer  "customer_id"
    t.decimal  "shipment_price",      precision: 8, scale: 2, default: 0.0
  end

  add_index "chatbot_orders", ["service_channel_id"], name: "index_chatbot_orders_on_service_channel_id", using: :btree
  add_index "chatbot_orders", ["shipment_method_id"], name: "index_chatbot_orders_on_shipment_method_id", using: :btree
  add_index "chatbot_orders", ["task_id"], name: "index_chatbot_orders_on_task_id", using: :btree

  create_table "chatbot_paytrail_payments", force: true do |t|
    t.integer  "chatbot_order_id"
    t.string   "paid"
    t.string   "method"
    t.datetime "payment_time"
    t.string   "return_auth"
    t.string   "url"
    t.string   "status",           default: "pending"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chatbot_product_attachments", force: true do |t|
    t.string   "file",               null: false
    t.string   "file_name",          null: false
    t.integer  "file_size"
    t.string   "file_type"
    t.integer  "chatbot_product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chatbot_products", force: true do |t|
    t.string   "title",                                               null: false
    t.decimal  "price",       precision: 8, scale: 2
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.boolean  "with_vat",                            default: false
    t.integer  "vat_id"
  end

  create_table "chatbot_stats", force: true do |t|
    t.integer  "answered_messages",            default: 0
    t.boolean  "switched_to_agent",            default: false
    t.string   "chat_channel_id",                              null: false
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "service_channel_id"
    t.integer  "dealing_time",       limit: 8
  end

  create_table "companies", force: true do |t|
    t.string   "name",                         limit: 100, default: "",         null: false
    t.string   "street_address",               limit: 250, default: "",         null: false
    t.string   "zip_code",                     limit: 100, default: "",         null: false
    t.string   "city",                         limit: 100, default: "",         null: false
    t.string   "code",                         limit: 100, default: "",         null: false
    t.integer  "contact_person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_zone",                                default: "Helsinki", null: false
    t.boolean  "inactive",                                 default: false
    t.string   "sms_provider"
    t.string   "wit_token"
    t.boolean  "allow_call_translation",                   default: false
    t.string   "wit_chatbot_token"
    t.boolean  "have_valid_wit_chatbot_token",             default: false
    t.string   "spare_parts_api_key",                      default: ""
    t.string   "currency",                                 default: "€"
    t.string   "paytrail_merchant_id"
    t.string   "paytrail_merchant_secret_key"
    t.string   "kimai_tracker_api_url"
  end

  create_table "company_files", force: true do |t|
    t.string   "file",       null: false
    t.string   "file_name",  null: false
    t.integer  "file_size"
    t.string   "file_type"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "company_stats", force: true do |t|
    t.integer  "company_id",                        null: false
    t.date     "date",                              null: false
    t.integer  "active_agents",         default: 0, null: false
    t.integer  "name_checks",           default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sms_sent",              default: 0, null: false
    t.integer  "sms_received",          default: 0, null: false
    t.integer  "call_tasks_received",   default: 0, null: false
    t.integer  "call_task_name_checks", default: 0, null: false
    t.integer  "call_task_autoreplies", default: 0, null: false
  end

  create_table "contacts", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "email"
    t.string   "website"
    t.string   "address"
    t.string   "city"
    t.string   "country"
    t.string   "vat"
    t.string   "postcode"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "agent_id"
  end

  add_index "contacts", ["agent_id"], name: "index_contacts_on_agent_id", using: :btree
  add_index "contacts", ["company_id"], name: "index_contacts_on_company_id", using: :btree

  create_table "credentials_tavoittajas", force: true do |t|
    t.string   "username",   null: false
    t.string   "password",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customer_task_notes", force: true do |t|
    t.integer  "customer_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "state",       default: 0
  end

  add_index "customer_task_notes", ["customer_id"], name: "index_customer_task_notes_on_customer_id", using: :btree

  create_table "customers", force: true do |t|
    t.string   "first_name"
    t.string   "contact_phone"
    t.string   "contact_email"
    t.string   "contact_website"
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "country"
    t.string   "vat"
    t.string   "postcode"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customers", ["company_id"], name: "index_customers_on_company_id", using: :btree
  add_index "customers", ["contact_email"], name: "index_customers_on_contact_email", using: :btree
  add_index "customers", ["contact_phone"], name: "index_customers_on_contact_phone", using: :btree
  add_index "customers", ["first_name"], name: "index_customers_on_first_name", using: :btree

  create_table "dashboard_layouts", force: true do |t|
    t.string   "name"
    t.integer  "size_x"
    t.integer  "size_y"
    t.integer  "company_id"
    t.boolean  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "layout"
    t.boolean  "dashboard_default", default: false
    t.boolean  "report_default",    default: false
  end

  create_table "drafts", force: true do |t|
    t.integer  "task_id"
    t.text     "description", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "entities", force: true do |t|
    t.string  "name"
    t.integer "company_id"
    t.json    "key_words",  default: []
  end

  create_table "follows", force: true do |t|
    t.integer  "task_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fonnecta_contact_caches", force: true do |t|
    t.integer  "company_id",                  null: false
    t.string   "phone_number",                null: false
    t.string   "full_name",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "city_name",      default: ""
    t.string   "street_address", default: ""
    t.string   "postal_code",    default: ""
    t.string   "post_office",    default: ""
  end

  create_table "fonnecta_credentials", force: true do |t|
    t.string   "client_id",       null: false
    t.string   "client_secret",   null: false
    t.string   "token"
    t.datetime "token_taken_at"
    t.integer  "token_expire_in"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "imap_settings", force: true do |t|
    t.string   "server_name",    limit: 100, default: "",    null: false
    t.string   "user_name",      limit: 100, default: "",    null: false
    t.string   "password",       limit: 100, default: "",    null: false
    t.text     "description",                default: "",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "port",                       default: 143
    t.boolean  "use_ssl",                    default: false
    t.string   "from_full_name", limit: 250, default: "",    null: false
    t.string   "from_email",     limit: 250, default: "",    null: false
    t.integer  "company_id"
  end

  create_table "intents", force: true do |t|
    t.string   "text"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "key_words", force: true do |t|
    t.string  "text"
    t.integer "entity_id", null: false
  end

  create_table "kimai_details", force: true do |t|
    t.string   "tracker_email"
    t.string   "tracker_auth_token"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "locations", force: true do |t|
    t.string   "name",           limit: 250, default: "", null: false
    t.string   "street_address", limit: 250, default: "", null: false
    t.string   "zip_code",       limit: 20,  default: "", null: false
    t.string   "city",           limit: 100, default: "", null: false
    t.string   "timezone",       limit: 20,  default: "", null: false
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations_managers", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "manager_id"
  end

  create_table "locations_reports", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "report_id"
  end

  create_table "locations_service_channels", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "service_channel_id"
  end

  create_table "locations_users", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "user_id"
  end

  create_table "media_channels", force: true do |t|
    t.integer  "service_channel_id"
    t.string   "type",                     limit: 50,                         default: "",    null: false
    t.integer  "imap_settings_id"
    t.integer  "smtp_settings_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "group_id",                                                    default: "",    null: false
    t.datetime "deleted_at"
    t.text     "autoreply_text"
    t.boolean  "active",                                                      default: true,  null: false
    t.boolean  "broken",                                                      default: false, null: false
    t.boolean  "name_check",                                                  default: false, null: false
    t.boolean  "send_autoreply",                                              default: true,  null: false
    t.decimal  "yellow_alert_hours",                  precision: 4, scale: 2
    t.integer  "yellow_alert_days"
    t.decimal  "red_alert_hours",                     precision: 4, scale: 2
    t.integer  "red_alert_days"
    t.integer  "chat_settings_id"
    t.integer  "sip_settings_id"
    t.string   "sms_sender"
    t.integer  "user_id"
    t.string   "autoreply_email_subject"
    t.boolean  "mark_done_on_call_action",                                    default: false
  end

  add_index "media_channels", ["deleted_at"], name: "index_media_channels_on_deleted_at", using: :btree
  add_index "media_channels", ["sip_settings_id"], name: "index_media_channels_on_sip_settings_id", using: :btree
  add_index "media_channels", ["user_id"], name: "index_media_channels_on_user_id", using: :btree

  create_table "message_attachments", force: true do |t|
    t.uuid     "message_id",                        null: false
    t.integer  "file",                              null: false
    t.string   "file_name",                         null: false
    t.integer  "file_size",                         null: false
    t.string   "content_type",                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "is_call_recording", default: false
  end

  add_index "message_attachments", ["deleted_at"], name: "index_message_attachments_on_deleted_at", using: :btree

  create_table "messages", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.integer  "number",                      default: 1,                     null: false
    t.string   "from",            limit: 250, default: "",                    null: false
    t.string   "to",              limit: 250, default: "",                    null: false
    t.string   "title",           limit: 250, default: "",                    null: false
    t.text     "description",                 default: "",                    null: false
    t.integer  "message_uid"
    t.string   "in_reply_to_id"
    t.integer  "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "is_internal",                 default: false,                 null: false
    t.boolean  "sms",                         default: false,                 null: false
    t.string   "channel_type",    limit: 20,  default: "email",               null: false
    t.datetime "deleted_at"
    t.boolean  "inbound",                     default: false
    t.json     "settings",                    default: {"cc"=>[], "bcc"=>[]}
    t.text     "call_transcript"
    t.integer  "cdr_call_log_id"
    t.boolean  "marked_as_read"
  end

  add_index "messages", ["deleted_at"], name: "index_messages_on_deleted_at", using: :btree
  add_index "messages", ["task_id", "message_uid"], name: "index_messages_on_task_id_and_message_uid", unique: true, using: :btree

  create_table "note_attachments", force: true do |t|
    t.integer  "note_id",      null: false
    t.integer  "file",         null: false
    t.string   "file_name",    null: false
    t.integer  "file_size",    null: false
    t.string   "content_type", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", force: true do |t|
    t.string   "name"
    t.integer  "company_id"
    t.boolean  "state",      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "priorities", force: true do |t|
    t.integer  "company_id"
    t.integer  "tag_id"
    t.integer  "priority_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "expire_time"
    t.text     "alarm_receivers"
    t.text     "email_template"
    t.text     "sms_template"
    t.datetime "deleted_at"
  end

  add_index "priorities", ["deleted_at"], name: "index_priorities_on_deleted_at", using: :btree

  create_table "product_images", force: true do |t|
    t.string   "file",               null: false
    t.string   "file_name",          null: false
    t.integer  "file_size"
    t.string   "file_type"
    t.integer  "chatbot_product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_templates", force: true do |t|
    t.text    "text",       null: false
    t.integer "company_id"
  end

  create_table "questions", force: true do |t|
    t.text     "text"
    t.integer  "intent_id"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recepient_emails", force: true do |t|
    t.string   "email"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "recepient_emails", ["user_id"], name: "index_recepient_emails_on_user_id", using: :btree

  create_table "reports", force: true do |t|
    t.string   "title",                       limit: 100, default: "",    null: false
    t.string   "kind",                        limit: 20,  default: "",    null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer  "company_id"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "send_to_emails",              limit: 500, default: "",    null: false
    t.string   "scheduled",                               default: "",    null: false
    t.datetime "last_sent_at"
    t.text     "media_channel_types",                     default: [],                 array: true
    t.string   "report_scope",                limit: 20,  default: "",    null: false
    t.string   "locale",                      limit: 20
    t.datetime "start_sending_at"
    t.boolean  "schedule_start_sent_already",             default: false, null: false
    t.integer  "dashboard_layout_id"
  end

  create_table "reports_service_channels", id: false, force: true do |t|
    t.integer "report_id"
    t.integer "service_channel_id"
  end

  create_table "reports_users", id: false, force: true do |t|
    t.integer "report_id"
    t.integer "user_id"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "schedule_entries", force: true do |t|
    t.integer  "weekly_schedule_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "weekday"
    t.datetime "fixed_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_channels", force: true do |t|
    t.string   "name",               limit: 100,                         default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "yellow_alert_days"
    t.decimal  "yellow_alert_hours",             precision: 4, scale: 2
    t.integer  "red_alert_days"
    t.decimal  "red_alert_hours",                precision: 4, scale: 2
    t.integer  "company_id"
    t.datetime "deleted_at"
    t.integer  "user_id"
    t.text     "signature"
  end

  add_index "service_channels", ["deleted_at"], name: "index_service_channels_on_deleted_at", using: :btree
  add_index "service_channels", ["user_id"], name: "index_service_channels_on_user_id", using: :btree

  create_table "service_channels_users", id: false, force: true do |t|
    t.integer "service_channel_id"
    t.integer "user_id"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shipment_methods", force: true do |t|
    t.string  "name"
    t.integer "company_id"
    t.decimal "price",      precision: 8, scale: 2
  end

  add_index "shipment_methods", ["company_id"], name: "index_shipment_methods_on_company_id", using: :btree

  create_table "sip_settings", force: true do |t|
    t.string   "title",         null: false
    t.string   "user_name",     null: false
    t.string   "password",      null: false
    t.string   "domain",        null: false
    t.string   "ws_server_url", null: false
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sip_widgets", force: true do |t|
    t.integer  "sip_settings_id"
    t.string   "button_1"
    t.string   "button_1_extension"
    t.string   "button_2"
    t.string   "button_2_extension"
    t.string   "button_3"
    t.string   "button_3_extension"
    t.string   "button_4"
    t.string   "button_4_extension"
    t.string   "button_5"
    t.string   "button_5_extension"
    t.string   "button_6"
    t.string   "button_6_extension"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "widget_button_color", default: "#26828e"
    t.string   "dial_color",          default: "#ffffff"
    t.string   "dial_bg_color",       default: "#26828e"
  end

  add_index "sip_widgets", ["sip_settings_id"], name: "index_sip_widgets_on_sip_settings_id", using: :btree

  create_table "sms_templates", force: true do |t|
    t.string   "title",              limit: 100, default: "", null: false
    t.text     "text"
    t.string   "kind",               limit: 20,  default: "", null: false
    t.integer  "service_channel_id"
    t.integer  "location_id"
    t.integer  "company_id"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "visibility",         limit: 20,  default: "", null: false
  end

  create_table "smtp_settings", force: true do |t|
    t.string   "server_name",       limit: 100, default: "",    null: false
    t.string   "user_name",         limit: 100, default: "",    null: false
    t.string   "password",          limit: 100, default: "",    null: false
    t.text     "description",                   default: "",    null: false
    t.integer  "port",                          default: 465,   null: false
    t.boolean  "use_ssl",                       default: true,  null: false
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "auth_method",       limit: 20,  default: "",    null: false
    t.boolean  "use_contakti_smtp",             default: false
  end

  create_table "super_admin_roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "super_admin_roles", ["name", "resource_type", "resource_id"], name: "super_admin_roles_index1", using: :btree
  add_index "super_admin_roles", ["name"], name: "index_super_admin_roles_on_name", using: :btree

  create_table "super_admins", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "username",               default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "super_admins", ["email"], name: "index_super_admins_on_email", unique: true, using: :btree
  add_index "super_admins", ["reset_password_token"], name: "index_super_admins_on_reset_password_token", unique: true, using: :btree
  add_index "super_admins", ["username"], name: "index_super_admins_on_username", unique: true, using: :btree

  create_table "super_admins_super_admin_roles", id: false, force: true do |t|
    t.integer "super_admin_id"
    t.integer "super_admin_role_id"
  end

  add_index "super_admins_super_admin_roles", ["super_admin_id", "super_admin_role_id"], name: "super_admin_roles_index2", using: :btree

  create_table "synonyms", force: true do |t|
    t.string  "text"
    t.integer "keyword_id", null: false
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "task_notes", force: true do |t|
    t.integer  "task_id",    null: false
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "task_versions", ["item_type", "item_id"], name: "index_task_versions_on_item_type_and_item_id", using: :btree

  create_table "tasks", force: true do |t|
    t.string   "state",                                limit: 100, default: "",                   null: false
    t.integer  "service_channel_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "uuid",                                             default: "uuid_generate_v4()"
    t.integer  "minutes_spent",                                    default: 0,                    null: false
    t.integer  "assigned_to_user_id"
    t.datetime "last_opened_at"
    t.datetime "opened_at"
    t.integer  "turnaround_time",                                  default: 0,                    null: false
    t.integer  "media_channel_id"
    t.datetime "deleted_at"
    t.datetime "assigned_at"
    t.string   "result",                               limit: 20,  default: "",                   null: false
    t.json     "data",                                             default: {},                   null: false
    t.integer  "created_by_user_id"
    t.boolean  "use_assigned_user_email_settings"
    t.integer  "customer_id"
    t.integer  "closed_by_user_id"
    t.boolean  "hidden"
    t.integer  "send_by_user_id"
    t.boolean  "open_to_all",                                      default: false
    t.boolean  "group_sms",                                        default: false
    t.integer  "campaign_item_id"
    t.boolean  "is_from_chatbot_custom_action_button",             default: false
    t.boolean  "is_softfone_ticket",                               default: false
  end

  add_index "tasks", ["campaign_item_id"], name: "index_tasks_on_campaign_item_id", using: :btree
  add_index "tasks", ["customer_id"], name: "index_tasks_on_customer_id", using: :btree
  add_index "tasks", ["deleted_at"], name: "index_tasks_on_deleted_at", using: :btree

  create_table "template_replies", force: true do |t|
    t.text     "text"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "third_party_tools", force: true do |t|
    t.integer  "company_id"
    t.text     "content"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timelogs", force: true do |t|
    t.integer  "user_id"
    t.integer  "minutes_worked"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "minutes_paused", default: 0, null: false
  end

  create_table "tracker_details", force: true do |t|
    t.integer  "tracker_id"
    t.integer  "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_sessions", force: true do |t|
    t.uuid     "session_id",  null: false
    t.integer  "user_id",     null: false
    t.string   "user_ip"
    t.string   "user_agent"
    t.datetime "accessed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_sessions", ["session_id"], name: "index_user_sessions_on_session_id", unique: true, using: :btree
  add_index "user_sessions", ["user_id", "session_id"], name: "index_user_sessions_on_user_id_and_session_id", using: :btree
  add_index "user_sessions", ["user_id"], name: "index_user_sessions_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "first_name",             limit: 100, default: "",    null: false
    t.string   "last_name",              limit: 250, default: "",    null: false
    t.string   "title",                  limit: 100, default: "",    null: false
    t.string   "mobile",                 limit: 100, default: "",    null: false
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                              default: "",    null: false
    t.string   "encrypted_password",                 default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "is_online",                          default: false, null: false
    t.boolean  "is_working",                         default: false, null: false
    t.datetime "started_working_at"
    t.datetime "went_offline_at"
    t.string   "authentication_token",   limit: 36,  default: "",    null: false
    t.text     "media_channel_types",                default: [],                 array: true
    t.integer  "default_location_id"
    t.datetime "last_seen_tasks"
    t.integer  "service_channel_id"
    t.text     "signature"
    t.integer  "sip_settings_id"
    t.string   "alias_name",             limit: 100, default: "",    null: false
    t.boolean  "in_call",                            default: false
    t.boolean  "is_dnd_active",                      default: false
    t.boolean  "is_transfer_active",                 default: false
    t.boolean  "is_acd_active",                      default: false
    t.boolean  "is_follow_active",                   default: false
    t.string   "locale",                             default: "fi"
  end

  add_index "users", ["default_location_id"], name: "index_users_on_default_location_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["sip_settings_id"], name: "index_users_on_sip_settings_id", using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "vats", force: true do |t|
    t.integer  "vat_percentage", default: 0
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weekly_schedules", force: true do |t|
    t.integer  "schedulable_id"
    t.string   "schedulable_type"
    t.boolean  "open_full_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
