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

ActiveRecord::Schema.define(version: 2019_07_05_113526) do

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

  create_table "application_states", force: :cascade do |t|
    t.string "type"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "balance_entries", force: :cascade do |t|
    t.bigint "balance_id"
    t.bigint "entry_id"
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "balance_amount_after", precision: 8, scale: 2
    t.decimal "base_currency_amount"
    t.index ["balance_id"], name: "index_balance_entries_on_balance_id"
    t.index ["entry_id"], name: "index_balance_entries_on_entry_id"
  end

  create_table "balance_entry_requests", force: :cascade do |t|
    t.bigint "entry_request_id"
    t.bigint "balance_entry_id"
    t.string "kind"
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["balance_entry_id"], name: "index_balance_entry_requests_on_balance_entry_id"
    t.index ["entry_request_id", "kind"], name: "index_balance_entry_requests_on_entry_request_id_and_kind", unique: true
    t.index ["entry_request_id"], name: "index_balance_entry_requests_on_entry_request_id"
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "wallet_id"
    t.string "kind"
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
    t.string "status"
    t.text "notification_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "void_factor", precision: 2, scale: 1
    t.string "validation_ticket_id"
    t.datetime "validation_ticket_sent_at"
    t.string "settlement_status"
    t.bigint "customer_bonus_id"
    t.decimal "base_currency_amount"
    t.string "notification_code"
    t.index ["currency_id"], name: "index_bets_on_currency_id"
    t.index ["customer_bonus_id"], name: "index_bets_on_customer_bonus_id"
    t.index ["customer_id"], name: "index_bets_on_customer_id"
    t.index ["odd_id"], name: "index_bets_on_odd_id"
  end

  create_table "betting_limits", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "title_id"
    t.integer "live_bet_delay"
    t.integer "user_max_bet"
    t.decimal "user_stake_factor"
    t.integer "max_loss"
    t.integer "max_win"
    t.decimal "live_stake_factor"
    t.index ["customer_id", "title_id"], name: "index_betting_limits_on_customer_id_and_title_id", unique: true
    t.index ["customer_id"], name: "index_betting_limits_on_customer_id"
    t.index ["title_id"], name: "index_betting_limits_on_title_id"
  end

  create_table "bonuses", force: :cascade do |t|
    t.string "code"
    t.string "kind"
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
    t.integer "percentage"
    t.boolean "repeatable", default: true, null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "text"
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "competitor_players", id: false, force: :cascade do |t|
    t.bigint "competitor_id"
    t.bigint "player_id"
    t.index ["competitor_id", "player_id"], name: "index_competitor_players_on_competitor_id_and_player_id", unique: true
    t.index ["competitor_id"], name: "index_competitor_players_on_competitor_id"
    t.index ["player_id"], name: "index_competitor_players_on_player_id"
  end

  create_table "competitors", force: :cascade do |t|
    t.string "name", null: false
    t.string "external_id", null: false
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_competitors_on_external_id", unique: true
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.boolean "primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "fiat", null: false
    t.decimal "exchange_rate", precision: 12, scale: 5
  end

  create_table "customer_bonuses", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "wallet_id"
    t.string "code"
    t.string "kind"
    t.decimal "rollover_multiplier"
    t.decimal "max_rollover_per_bet"
    t.decimal "max_deposit_match"
    t.decimal "min_odds_per_bet"
    t.decimal "min_deposit"
    t.integer "valid_for_days"
    t.integer "percentage"
    t.datetime "expires_at"
    t.integer "original_bonus_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "rollover_balance", precision: 8, scale: 2
    t.decimal "rollover_initial_value", precision: 8, scale: 2
    t.string "status", default: "initial", null: false
    t.bigint "balance_entry_id"
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.index ["balance_entry_id"], name: "index_customer_bonuses_on_balance_entry_id"
    t.index ["customer_id"], name: "index_customer_bonuses_on_customer_id"
    t.index ["wallet_id"], name: "index_customer_bonuses_on_wallet_id"
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

  create_table "customer_statistics", force: :cascade do |t|
    t.integer "deposit_count", default: 0
    t.decimal "deposit_value", precision: 8, scale: 2, default: "0.0"
    t.integer "withdrawal_count", default: 0
    t.decimal "withdrawal_value", precision: 8, scale: 2, default: "0.0"
    t.decimal "theoretical_bonus_cost", precision: 8, scale: 2, default: "0.0"
    t.decimal "potential_bonus_cost", precision: 8, scale: 2, default: "0.0"
    t.decimal "actual_bonus_cost", precision: 8, scale: 2, default: "0.0"
    t.integer "prematch_bet_count", default: 0
    t.decimal "prematch_wager", precision: 8, scale: 2, default: "0.0"
    t.decimal "prematch_payout", precision: 8, scale: 2, default: "0.0"
    t.integer "live_bet_count", default: 0
    t.decimal "live_sports_wager", precision: 8, scale: 2, default: "0.0"
    t.decimal "live_sports_payout", precision: 8, scale: 2, default: "0.0"
    t.decimal "total_pending_bet_sum", precision: 8, scale: 2, default: "0.0"
    t.bigint "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_statistics_on_customer_id"
  end

  create_table "customer_summaries", force: :cascade do |t|
    t.date "day", null: false
    t.decimal "bonus_wager_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "real_money_wager_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "bonus_payout_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "real_money_payout_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "bonus_deposit_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "real_money_deposit_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "withdraw_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "signups_count", default: 0, null: false
    t.integer "betting_customer_ids", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day"], name: "index_customer_summaries_on_day", unique: true
  end

  create_table "customer_transactions", force: :cascade do |t|
    t.string "type"
    t.string "status"
    t.bigint "actioned_by_id"
    t.bigint "customer_bonus_id"
    t.jsonb "details"
    t.datetime "finalized_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_message"
    t.index ["actioned_by_id"], name: "index_customer_transactions_on_actioned_by_id"
    t.index ["customer_bonus_id"], name: "index_customer_transactions_on_customer_bonus_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "gender"
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
    t.boolean "agreed_with_promotional", default: false
    t.boolean "locked", default: false
    t.datetime "locked_until"
    t.string "lock_reason"
    t.string "account_kind", default: "regular"
    t.integer "failed_attempts", default: 0, null: false
    t.boolean "email_verified", default: false, null: false
    t.boolean "verification_sent", default: false, null: false
    t.string "email_verification_token"
    t.string "b_tag"
    t.boolean "agreed_with_privacy"
    t.index ["activation_token"], name: "index_customers_on_activation_token", unique: true
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["email_verification_token"], name: "index_customers_on_email_verification_token", unique: true
    t.index ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true
    t.index ["username"], name: "index_customers_on_username", unique: true
  end

  create_table "deposit_limits", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "currency_id"
    t.integer "range"
    t.decimal "value"
    t.index ["currency_id"], name: "index_deposit_limits_on_currency_id"
    t.index ["customer_id"], name: "index_deposit_limits_on_customer_id"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "wallet_id"
    t.string "kind"
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "origin_type"
    t.bigint "origin_id"
    t.datetime "authorized_at"
    t.datetime "confirmed_at"
    t.string "external_id"
    t.bigint "entry_request_id"
    t.decimal "balance_amount_after", precision: 8, scale: 2
    t.decimal "base_currency_amount"
    t.index ["entry_request_id"], name: "index_entries_on_entry_request_id"
    t.index ["origin_type", "origin_id"], name: "index_entries_on_origin_type_and_origin_id"
    t.index ["wallet_id"], name: "index_entries_on_wallet_id"
  end

  create_table "entry_currency_rules", force: :cascade do |t|
    t.bigint "currency_id"
    t.string "kind"
    t.decimal "min_amount", precision: 8, scale: 2
    t.decimal "max_amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id", "kind"], name: "index_entry_currency_rules_on_currency_id_and_kind", unique: true
    t.index ["currency_id"], name: "index_entry_currency_rules_on_currency_id"
  end

  create_table "entry_requests", force: :cascade do |t|
    t.string "status", default: "initial"
    t.json "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.integer "currency_id"
    t.string "kind"
    t.text "comment"
    t.decimal "amount", precision: 8, scale: 2
    t.string "initiator_type"
    t.bigint "initiator_id"
    t.string "mode"
    t.string "origin_type"
    t.bigint "origin_id"
    t.string "external_id"
    t.index ["initiator_type", "initiator_id"], name: "index_entry_requests_on_initiator_type_and_initiator_id"
    t.index ["origin_type", "origin_id"], name: "index_entry_requests_on_origin_type_and_origin_id"
  end

  create_table "event_competitors", id: false, force: :cascade do |t|
    t.bigint "event_id"
    t.bigint "competitor_id"
    t.string "qualifier"
    t.index ["competitor_id"], name: "index_event_competitors_on_competitor_id"
    t.index ["event_id", "competitor_id"], name: "index_event_competitors_on_event_id_and_competitor_id", unique: true
    t.index ["event_id"], name: "index_event_competitors_on_event_id"
  end

  create_table "event_scopes", force: :cascade do |t|
    t.bigint "title_id"
    t.bigint "event_scope_id"
    t.string "name"
    t.string "kind", default: "tournament"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.integer "position", default: 9999, null: false
    t.index ["event_scope_id"], name: "index_event_scopes_on_event_scope_id"
    t.index ["external_id"], name: "index_event_scopes_on_external_id", unique: true
    t.index ["position"], name: "index_event_scopes_on_position"
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
    t.datetime "remote_updated_at"
    t.boolean "traded_live", default: false
    t.string "status", default: "not_started"
    t.integer "priority", limit: 2, default: 1
    t.boolean "visible", default: true
    t.boolean "active", default: false
    t.bigint "producer_id"
    t.string "display_status"
    t.integer "home_score"
    t.integer "away_score"
    t.integer "time_in_seconds"
    t.string "liveodds"
    t.boolean "ready", default: false
    t.index ["active"], name: "index_events_on_active"
    t.index ["external_id"], name: "index_events_on_external_id", unique: true
    t.index ["producer_id"], name: "index_events_on_producer_id"
    t.index ["title_id"], name: "index_events_on_title_id"
  end

  create_table "label_joins", force: :cascade do |t|
    t.bigint "label_id"
    t.integer "labelable_id"
    t.string "labelable_type"
    t.index ["label_id"], name: "index_label_joins_on_label_id"
    t.index ["labelable_id", "labelable_type"], name: "index_label_joins_on_labelable_id_and_labelable_type"
  end

  create_table "labels", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "kind", default: "customer"
    t.index ["deleted_at"], name: "index_labels_on_deleted_at"
  end

  create_table "market_templates", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name"
    t.string "groups"
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.index ["external_id"], name: "index_market_templates_on_external_id"
  end

  create_table "markets", force: :cascade do |t|
    t.bigint "event_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority"
    t.string "external_id"
    t.string "status"
    t.boolean "visible", default: true
    t.string "category"
    t.string "previous_status"
    t.string "template_id"
    t.string "template_specifiers"
    t.index ["event_id"], name: "index_markets_on_event_id"
    t.index ["external_id"], name: "index_markets_on_external_id", unique: true
  end

  create_table "odds", force: :cascade do |t|
    t.bigint "market_id"
    t.string "name"
    t.boolean "won"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.decimal "value"
    t.string "status"
    t.string "outcome_id", default: ""
    t.index ["external_id"], name: "index_odds_on_external_id", unique: true
    t.index ["market_id"], name: "index_odds_on_market_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.string "external_id", null: false
    t.string "full_name"
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_players_on_external_id", unique: true
  end

  create_table "radar_providers", force: :cascade do |t|
    t.string "code"
    t.string "state"
    t.datetime "last_successful_subscribed_at"
    t.datetime "recover_requested_at"
    t.integer "recovery_snapshot_id"
    t.integer "recovery_node_id"
    t.datetime "last_disconnection_at"
    t.index ["code"], name: "index_radar_providers_on_code"
    t.index ["recovery_snapshot_id"], name: "index_radar_providers_on_recovery_snapshot_id"
  end

  create_table "scoped_events", force: :cascade do |t|
    t.bigint "event_scope_id"
    t.bigint "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "event_scope_id"], name: "index_scoped_events_on_event_id_and_event_scope_id", unique: true
    t.index ["event_id"], name: "index_scoped_events_on_event_id"
    t.index ["event_scope_id"], name: "index_scoped_events_on_event_scope_id"
  end

  create_table "titles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "esports"
    t.string "external_id"
    t.boolean "show_category_in_navigation", default: true
    t.integer "position", default: 9999, null: false
    t.index ["external_id"], name: "index_titles_on_external_id", unique: true
    t.index ["position"], name: "index_titles_on_position"
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
    t.integer "failed_attempts", default: 0, null: false
    t.string "time_zone"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "verification_documents", force: :cascade do |t|
    t.bigint "customer_id"
    t.string "kind"
    t.string "status"
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
    t.index ["customer_id", "currency_id"], name: "index_wallets_on_customer_id_and_currency_id", unique: true
    t.index ["customer_id"], name: "index_wallets_on_customer_id"
  end

  add_foreign_key "addresses", "customers"
  add_foreign_key "balance_entries", "balances"
  add_foreign_key "balance_entries", "entries", on_delete: :cascade
  add_foreign_key "balances", "wallets"
  add_foreign_key "bets", "currencies"
  add_foreign_key "bets", "customers"
  add_foreign_key "bets", "odds", on_delete: :cascade
  add_foreign_key "betting_limits", "customers"
  add_foreign_key "betting_limits", "titles"
  add_foreign_key "competitor_players", "competitors", on_delete: :cascade
  add_foreign_key "competitor_players", "players", on_delete: :cascade
  add_foreign_key "customer_bonuses", "balance_entries", on_delete: :cascade
  add_foreign_key "customer_notes", "customers"
  add_foreign_key "customer_notes", "users"
  add_foreign_key "customer_statistics", "customers"
  add_foreign_key "customer_transactions", "customer_bonuses", on_delete: :cascade
  add_foreign_key "customer_transactions", "users", column: "actioned_by_id"
  add_foreign_key "deposit_limits", "currencies"
  add_foreign_key "deposit_limits", "customers"
  add_foreign_key "entries", "entry_requests", on_delete: :cascade
  add_foreign_key "entries", "wallets"
  add_foreign_key "entry_currency_rules", "currencies"
  add_foreign_key "entry_requests", "currencies"
  add_foreign_key "entry_requests", "customers"
  add_foreign_key "event_competitors", "competitors", on_delete: :cascade
  add_foreign_key "event_competitors", "events", on_delete: :cascade
  add_foreign_key "event_scopes", "event_scopes"
  add_foreign_key "event_scopes", "titles"
  add_foreign_key "events", "radar_providers", column: "producer_id"
  add_foreign_key "events", "titles"
  add_foreign_key "label_joins", "labels"
  add_foreign_key "markets", "events", on_delete: :cascade
  add_foreign_key "odds", "markets", on_delete: :cascade
  add_foreign_key "scoped_events", "event_scopes"
  add_foreign_key "scoped_events", "events", on_delete: :cascade
  add_foreign_key "verification_documents", "customers"
  add_foreign_key "wallets", "currencies"
  add_foreign_key "wallets", "customers"
end
