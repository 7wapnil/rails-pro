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

ActiveRecord::Schema.define(version: 2019_12_30_211311) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
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

  create_table "bets", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "odd_id"
    t.bigint "currency_id"
    t.decimal "amount", precision: 14, scale: 2
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
    t.boolean "counted_towards_rollover", default: false
    t.datetime "bet_settlement_status_achieved_at"
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
    t.boolean "casino", default: false, null: false
    t.boolean "sportsbook", default: true, null: false
    t.decimal "sportsbook_multiplier", default: "1.0", null: false
    t.decimal "max_rollover_per_spin"
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

  create_table "crypto_addresses", force: :cascade do |t|
    t.text "address", default: ""
    t.bigint "wallet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wallet_id"], name: "index_crypto_addresses_on_wallet_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.boolean "primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "fiat", null: false
    t.decimal "exchange_rate", precision: 12, scale: 5
    t.index ["code"], name: "index_currencies_on_code", unique: true
    t.index ["name"], name: "index_currencies_on_name", unique: true
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
    t.bigint "original_bonus_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "rollover_balance", precision: 14, scale: 2
    t.decimal "rollover_initial_value", precision: 14, scale: 2
    t.string "status", default: "initial", null: false
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.bigint "entry_id"
    t.boolean "casino", default: false, null: false
    t.boolean "sportsbook", default: true, null: false
    t.decimal "sportsbook_multiplier", default: "1.0", null: false
    t.decimal "max_rollover_per_spin"
    t.index ["customer_id"], name: "index_customer_bonuses_on_customer_id"
    t.index ["entry_id"], name: "index_customer_bonuses_on_entry_id"
    t.index ["wallet_id"], name: "index_customer_bonuses_on_wallet_id"
  end

  create_table "customer_data", force: :cascade do |t|
    t.bigint "customer_id"
    t.string "traffic_type_last"
    t.string "utm_source_last"
    t.string "utm_medium_last"
    t.string "utm_campaign_last"
    t.string "utm_content_last"
    t.string "utm_term_last"
    t.string "visitcount_last"
    t.string "browser_last"
    t.string "device_type_last"
    t.string "device_platform_last"
    t.string "ip_last"
    t.string "registration_url_last"
    t.string "timestamp_visit_last"
    t.string "entrance_page_last"
    t.string "referrer_last"
    t.string "current_btag"
    t.string "traffic_type_first"
    t.string "utm_source_first"
    t.string "utm_medium_first"
    t.string "utm_campaign_first"
    t.string "utm_term_first"
    t.string "timestamp_visit_first"
    t.string "entrance_page_first"
    t.string "referrer_first"
    t.string "ga_client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_data_on_customer_id"
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
    t.decimal "deposit_value", precision: 14, scale: 2, default: "0.0"
    t.integer "withdrawal_count", default: 0
    t.decimal "withdrawal_value", precision: 14, scale: 2, default: "0.0"
    t.integer "prematch_bet_count", default: 0
    t.decimal "prematch_wager", precision: 14, scale: 2, default: "0.0"
    t.decimal "prematch_payout", precision: 14, scale: 2, default: "0.0"
    t.integer "live_bet_count", default: 0
    t.decimal "live_sports_wager", precision: 14, scale: 2, default: "0.0"
    t.decimal "live_sports_payout", precision: 14, scale: 2, default: "0.0"
    t.decimal "total_pending_bet_sum", precision: 14, scale: 2, default: "0.0"
    t.bigint "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_updated_at"
    t.decimal "total_bonus_awarded", precision: 14, scale: 2, default: "0.0"
    t.decimal "total_bonus_completed", precision: 14, scale: 2, default: "0.0"
    t.integer "casino_game_count", default: 0
    t.decimal "casino_game_wager", precision: 14, scale: 2, default: "0.0"
    t.decimal "casino_game_payout", precision: 14, scale: 2, default: "0.0"
    t.integer "live_casino_count", default: 0
    t.decimal "live_casino_wager", precision: 14, scale: 2, default: "0.0"
    t.decimal "live_casino_payout", precision: 14, scale: 2, default: "0.0"
    t.index ["customer_id"], name: "index_customer_statistics_on_customer_id"
  end

  create_table "customer_summaries", force: :cascade do |t|
    t.date "day", null: false
    t.decimal "bonus_wager_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "real_money_wager_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "bonus_payout_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "real_money_payout_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "bonus_deposit_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "real_money_deposit_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "withdraw_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "signups_count", default: 0, null: false
    t.integer "betting_customer_ids", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "casino_customer_ids", default: [], null: false, array: true
    t.decimal "casino_bonus_wager_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "casino_real_money_wager_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "casino_bonus_payout_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "casino_real_money_payout_amount", precision: 14, scale: 2, default: "0.0", null: false
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
    t.bigint "external_id"
    t.inet "sign_up_ip"
    t.integer "visit_count", default: 0
    t.datetime "last_visit_at"
    t.inet "last_visit_ip"
    t.datetime "last_activity_at"
    t.index ["activation_token"], name: "index_customers_on_activation_token", unique: true
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["email_verification_token"], name: "index_customers_on_email_verification_token", unique: true
    t.index ["external_id"], name: "index_customers_on_external_id", unique: true
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
    t.decimal "amount", precision: 14, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "origin_type"
    t.bigint "origin_id"
    t.datetime "authorized_at"
    t.datetime "confirmed_at"
    t.string "external_id"
    t.bigint "entry_request_id"
    t.decimal "balance_amount_after", precision: 14, scale: 2
    t.decimal "base_currency_amount"
    t.decimal "real_money_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "base_currency_real_money_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "bonus_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "base_currency_bonus_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "bonus_amount_after", precision: 14, scale: 2, default: "0.0"
    t.decimal "cancelled_bonus_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "base_currency_cancelled_bonus_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "cancelled_bonus_amount_after", precision: 14, scale: 2, default: "0.0"
    t.index ["entry_request_id"], name: "index_entries_on_entry_request_id"
    t.index ["origin_type", "origin_id"], name: "index_entries_on_origin_type_and_origin_id"
    t.index ["wallet_id"], name: "index_entries_on_wallet_id"
  end

  create_table "entry_currency_rules", force: :cascade do |t|
    t.bigint "currency_id"
    t.string "kind"
    t.decimal "min_amount", precision: 14, scale: 2
    t.decimal "max_amount", precision: 14, scale: 2
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
    t.decimal "amount", precision: 14, scale: 2
    t.string "initiator_type"
    t.bigint "initiator_id"
    t.string "mode"
    t.string "origin_type"
    t.bigint "origin_id"
    t.string "external_id"
    t.decimal "real_money_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "bonus_amount", precision: 14, scale: 2, default: "0.0"
    t.decimal "cancelled_bonus_amount", precision: 14, scale: 2, default: "0.0"
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
    t.datetime "twitch_start_time"
    t.datetime "twitch_end_time"
    t.string "twitch_url"
    t.index ["active"], name: "index_events_on_active"
    t.index ["external_id"], name: "index_events_on_external_id", unique: true
    t.index ["producer_id"], name: "index_events_on_producer_id"
    t.index ["title_id"], name: "index_events_on_title_id"
  end

  create_table "every_matrix_categories", force: :cascade do |t|
    t.string "context"
    t.string "label", default: ""
    t.integer "position"
    t.string "kind"
    t.index ["context"], name: "index_every_matrix_categories_on_context"
  end

  create_table "every_matrix_content_providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "logo_url"
    t.boolean "enabled", default: false
    t.string "representation_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: false
    t.boolean "as_vendor", default: false
    t.string "internal_image_name", default: ""
    t.string "slug", default: ""
    t.index ["name"], name: "index_every_matrix_content_providers_on_name"
    t.index ["representation_name"], name: "index_every_matrix_content_providers_on_representation_name"
  end

  create_table "every_matrix_game_details", force: :cascade do |t|
    t.string "help_url"
    t.decimal "top_prize", precision: 14, scale: 2
    t.decimal "min_hit_frequency", precision: 9, scale: 4, default: "0.0"
    t.decimal "max_hit_frequency", precision: 9, scale: 4, default: "0.0"
    t.boolean "free_spin_supported", default: false
    t.boolean "free_spin_bonus_supported", default: false
    t.string "launch_game_in_html_5", default: ""
    t.string "play_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["play_item_id"], name: "index_every_matrix_game_details_on_play_item_id"
  end

  create_table "every_matrix_jackpots", force: :cascade do |t|
    t.integer "base_currency_amount", default: 0
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_every_matrix_jackpots_on_external_id"
  end

  create_table "every_matrix_play_item_categories", force: :cascade do |t|
    t.string "play_item_id", null: false
    t.bigint "category_id", null: false
    t.integer "position"
    t.index ["category_id"], name: "index_every_matrix_play_item_categories_on_category_id"
    t.index ["play_item_id", "category_id"], name: "category_play_item_upsert", unique: true
    t.index ["play_item_id"], name: "index_every_matrix_play_item_categories_on_play_item_id"
  end

  create_table "every_matrix_play_items", primary_key: "external_id", id: :string, force: :cascade do |t|
    t.string "type", null: false
    t.string "slug"
    t.decimal "theoretical_payout", precision: 14, scale: 2, default: "0.0"
    t.decimal "third_party_fee", precision: 14, scale: 2, default: "0.0"
    t.decimal "fpp", precision: 14, scale: 2, default: "0.0"
    t.text "restricted_territories", default: [], array: true
    t.text "languages", default: [], array: true
    t.text "currencies", default: [], array: true
    t.string "terminal", default: [], array: true
    t.string "tags", default: [], array: true
    t.string "url"
    t.datetime "external_created_at"
    t.datetime "external_updated_at"
    t.decimal "popularity_coefficient", precision: 6, scale: 4, default: "0.0"
    t.integer "popularity_ranking", default: 0
    t.boolean "play_mode_fun", default: false
    t.boolean "play_mode_anonymity", default: false
    t.boolean "play_mode_real_money", default: false
    t.string "name"
    t.string "short_name"
    t.string "description"
    t.string "thumbnail_url"
    t.string "logo_url"
    t.string "background_image_url"
    t.string "small_icon_url"
    t.string "medium_icon_url"
    t.string "large_icon_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "every_matrix_vendor_id"
    t.bigint "every_matrix_content_provider_id"
    t.decimal "bonus_contribution", default: "1.0", null: false
    t.datetime "last_updated_recommended_games_at"
    t.string "game_code"
    t.index ["every_matrix_content_provider_id"], name: "index_play_items_on_content_providers_id"
    t.index ["every_matrix_vendor_id"], name: "index_play_items_on_vendors_id"
    t.index ["slug"], name: "index_every_matrix_play_items_on_slug"
    t.index ["type"], name: "index_every_matrix_play_items_on_type"
  end

  create_table "every_matrix_recommended_games_relationships", force: :cascade do |t|
    t.string "original_game_id"
    t.string "recommended_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["original_game_id"], name: "index_original_game_on_play_item"
    t.index ["recommended_game_id"], name: "index_recommended_game_on_play_item"
  end

  create_table "every_matrix_table_details", force: :cascade do |t|
    t.boolean "is_vip_table", default: false
    t.boolean "is_open", default: false
    t.boolean "is_seats_unlimited", default: false
    t.boolean "is_bet_behind_available", default: false
    t.decimal "max_limit", precision: 9, scale: 4, default: "0.0"
    t.decimal "min_limit", precision: 9, scale: 4, default: "0.0"
    t.string "play_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["play_item_id"], name: "index_every_matrix_table_details_on_play_item_id"
  end

  create_table "every_matrix_transactions", force: :cascade do |t|
    t.string "type"
    t.uuid "wallet_session_id"
    t.bigint "customer_id"
    t.decimal "amount", precision: 14, scale: 2
    t.string "game_type"
    t.string "gp_game_id"
    t.integer "gp_id"
    t.string "em_game_id"
    t.string "product"
    t.string "round_id"
    t.string "device"
    t.bigint "transaction_id", null: false
    t.string "round_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "response"
    t.decimal "real_money_ratio", default: "1.0", null: false
    t.bigint "customer_bonus_id"
    t.index ["customer_bonus_id"], name: "index_every_matrix_transactions_on_customer_bonus_id"
    t.index ["customer_id"], name: "index_every_matrix_transactions_on_customer_id"
    t.index ["round_id"], name: "index_every_matrix_transactions_on_round_id"
    t.index ["transaction_id"], name: "index_every_matrix_transactions_on_transaction_id"
    t.index ["wallet_session_id"], name: "index_every_matrix_transactions_on_wallet_session_id"
  end

  create_table "every_matrix_vendors", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "vendor_id", null: false
    t.string "logo_url"
    t.text "restricted_territories", default: [], array: true
    t.boolean "enabled", default: false
    t.text "languages", default: [], array: true
    t.text "currencies", default: [], array: true
    t.boolean "has_live_casino", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: false
    t.string "internal_image_name", default: ""
    t.string "slug", default: ""
    t.index ["vendor_id"], name: "index_every_matrix_vendors_on_vendor_id"
  end

  create_table "every_matrix_wallet_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "wallet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "play_item_id", null: false
    t.index ["play_item_id"], name: "index_every_matrix_wallet_sessions_on_play_item_id"
    t.index ["wallet_id"], name: "index_every_matrix_wallet_sessions_on_wallet_id"
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

  create_table "login_activities", force: :cascade do |t|
    t.string "scope"
    t.string "strategy"
    t.string "identity"
    t.boolean "success"
    t.string "failure_reason"
    t.string "user_type"
    t.bigint "user_id"
    t.string "context"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.datetime "created_at"
    t.index ["identity"], name: "index_login_activities_on_identity"
    t.index ["ip"], name: "index_login_activities_on_ip"
    t.index ["user_type", "user_id"], name: "index_login_activities_on_user_type_and_user_id"
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
    t.string "previous_status"
    t.string "template_specifiers"
    t.bigint "template_id"
    t.bigint "producer_id"
    t.index ["event_id"], name: "index_markets_on_event_id"
    t.index ["external_id"], name: "index_markets_on_external_id", unique: true
    t.index ["producer_id"], name: "index_markets_on_producer_id"
    t.index ["template_id"], name: "index_markets_on_template_id"
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

  create_table "radar_producers", force: :cascade do |t|
    t.string "code"
    t.string "state"
    t.datetime "last_subscribed_at"
    t.datetime "recovery_requested_at"
    t.integer "recovery_snapshot_id"
    t.integer "recovery_node_id"
    t.datetime "last_disconnected_at"
    t.index ["code"], name: "index_radar_producers_on_code"
    t.index ["recovery_snapshot_id"], name: "index_radar_producers_on_recovery_snapshot_id"
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
    t.string "external_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "esports"
    t.string "external_id"
    t.boolean "show_category_in_navigation", default: true
    t.integer "position", default: 9999, null: false
    t.string "short_name"
    t.string "name"
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
    t.decimal "real_money_balance", precision: 14, scale: 2, default: "0.0"
    t.decimal "bonus_balance", precision: 14, scale: 2, default: "0.0"
    t.decimal "cancelled_bonus_balance", precision: 14, scale: 2, default: "0.0"
    t.index ["currency_id"], name: "index_wallets_on_currency_id"
    t.index ["customer_id", "currency_id"], name: "index_wallets_on_customer_id_and_currency_id", unique: true
    t.index ["customer_id"], name: "index_wallets_on_customer_id"
  end

  add_foreign_key "addresses", "customers"
  add_foreign_key "bets", "currencies"
  add_foreign_key "bets", "customers"
  add_foreign_key "bets", "odds", on_delete: :cascade
  add_foreign_key "betting_limits", "customers"
  add_foreign_key "betting_limits", "titles"
  add_foreign_key "competitor_players", "competitors", on_delete: :cascade
  add_foreign_key "competitor_players", "players", on_delete: :cascade
  add_foreign_key "crypto_addresses", "wallets"
  add_foreign_key "customer_bonuses", "bonuses", column: "original_bonus_id"
  add_foreign_key "customer_bonuses", "entries"
  add_foreign_key "customer_data", "customers"
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
  add_foreign_key "events", "radar_producers", column: "producer_id"
  add_foreign_key "events", "titles"
  add_foreign_key "every_matrix_game_details", "every_matrix_play_items", column: "play_item_id", primary_key: "external_id"
  add_foreign_key "every_matrix_play_item_categories", "every_matrix_categories", column: "category_id"
  add_foreign_key "every_matrix_play_item_categories", "every_matrix_play_items", column: "play_item_id", primary_key: "external_id"
  add_foreign_key "every_matrix_play_items", "every_matrix_content_providers"
  add_foreign_key "every_matrix_play_items", "every_matrix_vendors"
  add_foreign_key "every_matrix_recommended_games_relationships", "every_matrix_play_items", column: "original_game_id", primary_key: "external_id"
  add_foreign_key "every_matrix_recommended_games_relationships", "every_matrix_play_items", column: "recommended_game_id", primary_key: "external_id"
  add_foreign_key "every_matrix_table_details", "every_matrix_play_items", column: "play_item_id", primary_key: "external_id"
  add_foreign_key "every_matrix_transactions", "customer_bonuses"
  add_foreign_key "every_matrix_transactions", "customers"
  add_foreign_key "every_matrix_transactions", "every_matrix_wallet_sessions", column: "wallet_session_id"
  add_foreign_key "every_matrix_wallet_sessions", "every_matrix_play_items", column: "play_item_id", primary_key: "external_id"
  add_foreign_key "label_joins", "labels"
  add_foreign_key "markets", "events", on_delete: :cascade
  add_foreign_key "markets", "market_templates", column: "template_id", on_delete: :nullify
  add_foreign_key "markets", "radar_producers", column: "producer_id"
  add_foreign_key "odds", "markets", on_delete: :cascade
  add_foreign_key "scoped_events", "event_scopes"
  add_foreign_key "scoped_events", "events", on_delete: :cascade
  add_foreign_key "verification_documents", "customers"
  add_foreign_key "wallets", "currencies"
  add_foreign_key "wallets", "customers"
end
