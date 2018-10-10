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

ActiveRecord::Schema.define(version: 2018_10_10_115141) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "customer_id"
    t.string "country"
    t.string "state"
    t.string "city"
    t.string "street_address"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_addresses_on_customer_id"
  end

  create_table "balance_entries", force: :cascade do |t|
    t.bigint "balance_id"
    t.bigint "entry_id"
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["balance_id"], name: "index_balance_entries_on_balance_id"
    t.index ["entry_id"], name: "index_balance_entries_on_entry_id"
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "wallet_id"
    t.integer "kind"
    t.decimal "amount", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wallet_id"], name: "index_balances_on_wallet_id"
  end

  create_table "bets", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "odd_id"
    t.bigint "currency_id"
    t.decimal "amount"
    t.decimal "odd_value"
    t.integer "status"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "result", default: false
    t.decimal "void_factor", precision: 2, scale: 1
    t.string "validation_ticket_id"
    t.index ["currency_id"], name: "index_bets_on_currency_id"
    t.index ["customer_id"], name: "index_bets_on_customer_id"
    t.index ["odd_id"], name: "index_bets_on_odd_id"
  end

  create_table "bonuses", force: :cascade do |t|
    t.string "code"
    t.integer "kind"
    t.decimal "rollover_multiplier"
    t.decimal "max_rollover_per_bet"
    t.decimal "max_deposit_match"
    t.decimal "min_odds_per_bet"
    t.decimal "min_deposit"
    t.integer "valid_for_days"
    t.datetime "expires_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.boolean "primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_notes", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "user_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["customer_id"], name: "index_customer_notes_on_customer_id"
    t.index ["deleted_at"], name: "index_customer_notes_on_deleted_at"
    t.index ["user_id"], name: "index_customer_notes_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.integer "gender"
    t.date "date_of_birth"
    t.string "phone"
    t.string "email"
    t.string "username", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "verified", default: false
    t.boolean "activated", default: false
    t.string "activation_token"
    t.index ["activation_token"], name: "index_customers_on_activation_token", unique: true
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true
    t.index ["username"], name: "index_customers_on_username", unique: true
  end

  create_table "customers_labels", id: false, force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "label_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["customer_id"], name: "index_customers_labels_on_customer_id"
    t.index ["label_id"], name: "index_customers_labels_on_label_id"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "wallet_id"
    t.integer "kind"
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "origin_type"
    t.bigint "origin_id"
    t.datetime "authorized_at"
    t.index ["origin_type", "origin_id"], name: "index_entries_on_origin_type_and_origin_id"
    t.index ["wallet_id"], name: "index_entries_on_wallet_id"
  end

  create_table "entry_currency_rules", force: :cascade do |t|
    t.bigint "currency_id"
    t.integer "kind"
    t.decimal "min_amount", precision: 8, scale: 2
    t.decimal "max_amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id", "kind"], name: "index_entry_currency_rules_on_currency_id_and_kind", unique: true
    t.index ["currency_id"], name: "index_entry_currency_rules_on_currency_id"
  end

  create_table "entry_requests", force: :cascade do |t|
    t.integer "status", default: 0
    t.json "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.integer "currency_id"
    t.integer "kind"
    t.text "comment"
    t.decimal "amount", precision: 8, scale: 2
    t.string "initiator_type"
    t.bigint "initiator_id"
    t.integer "mode"
    t.string "origin_type"
    t.bigint "origin_id"
    t.index ["initiator_type", "initiator_id"], name: "index_entry_requests_on_initiator_type_and_initiator_id"
    t.index ["origin_type", "origin_id"], name: "index_entry_requests_on_origin_type_and_origin_id"
  end

  create_table "event_scopes", force: :cascade do |t|
    t.bigint "title_id"
    t.bigint "event_scope_id"
    t.string "name"
    t.integer "kind", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["event_scope_id"], name: "index_event_scopes_on_event_scope_id"
    t.index ["external_id"], name: "index_event_scopes_on_external_id"
    t.index ["title_id"], name: "index_event_scopes_on_title_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "title_id"
    t.string "name"
    t.text "description"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.json "payload"
    t.datetime "remote_updated_at"
    t.boolean "traded_live", default: false
    t.integer "status", default: 0
    t.index ["external_id"], name: "index_events_on_external_id"
    t.index ["title_id"], name: "index_events_on_title_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_labels_on_deleted_at"
  end

  create_table "market_templates", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name"
    t.string "groups"
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_market_templates_on_external_id"
  end

  create_table "markets", force: :cascade do |t|
    t.bigint "event_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority"
    t.string "external_id"
    t.integer "status"
    t.index ["event_id"], name: "index_markets_on_event_id"
    t.index ["external_id"], name: "index_markets_on_external_id"
  end

  create_table "odds", force: :cascade do |t|
    t.bigint "market_id"
    t.string "name"
    t.boolean "won"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.decimal "value"
    t.integer "status"
    t.index ["external_id"], name: "index_odds_on_external_id"
    t.index ["market_id"], name: "index_odds_on_market_id"
  end

  create_table "scoped_events", force: :cascade do |t|
    t.bigint "event_scope_id"
    t.bigint "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_scoped_events_on_event_id"
    t.index ["event_scope_id"], name: "index_scoped_events_on_event_scope_id"
  end

  create_table "titles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "kind", default: 0
    t.string "external_id"
    t.index ["external_id"], name: "index_titles_on_external_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "verification_documents", force: :cascade do |t|
    t.bigint "customer_id"
    t.integer "kind"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["customer_id"], name: "index_verification_documents_on_customer_id"
    t.index ["deleted_at"], name: "index_verification_documents_on_deleted_at"
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "customer_id"
    t.decimal "amount", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "currency_id"
    t.index ["currency_id"], name: "index_wallets_on_currency_id"
    t.index ["customer_id"], name: "index_wallets_on_customer_id"
  end

  add_foreign_key "addresses", "customers"
  add_foreign_key "balance_entries", "balances"
  add_foreign_key "balance_entries", "entries"
  add_foreign_key "balances", "wallets"
  add_foreign_key "bets", "currencies"
  add_foreign_key "bets", "customers"
  add_foreign_key "bets", "odds"
  add_foreign_key "customer_notes", "customers"
  add_foreign_key "customer_notes", "users"
  add_foreign_key "entries", "wallets"
  add_foreign_key "entry_currency_rules", "currencies"
  add_foreign_key "entry_requests", "currencies"
  add_foreign_key "entry_requests", "customers"
  add_foreign_key "event_scopes", "event_scopes"
  add_foreign_key "event_scopes", "titles"
  add_foreign_key "events", "titles"
  add_foreign_key "markets", "events"
  add_foreign_key "odds", "markets"
  add_foreign_key "scoped_events", "event_scopes"
  add_foreign_key "scoped_events", "events"
  add_foreign_key "verification_documents", "customers"
  add_foreign_key "wallets", "currencies"
  add_foreign_key "wallets", "customers"
end
