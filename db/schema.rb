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

ActiveRecord::Schema.define(version: 2018_05_03_095735) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "disciplines", force: :cascade do |t|
    t.string "name"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.bigint "discipline_id"
    t.bigint "event_id"
    t.string "name"
    t.string "kind"
    t.text "description"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discipline_id"], name: "index_events_on_discipline_id"
    t.index ["event_id"], name: "index_events_on_event_id"
  end

  create_table "markets", force: :cascade do |t|
    t.bigint "event_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_markets_on_event_id"
  end

  create_table "odd_values", force: :cascade do |t|
    t.bigint "odd_id"
    t.decimal "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["odd_id"], name: "index_odd_values_on_odd_id"
  end

  create_table "odds", force: :cascade do |t|
    t.bigint "market_id"
    t.string "name"
    t.boolean "won"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_id"], name: "index_odds_on_market_id"
  end

  add_foreign_key "events", "disciplines"
  add_foreign_key "events", "events"
  add_foreign_key "markets", "events"
  add_foreign_key "odd_values", "odds"
  add_foreign_key "odds", "markets"
end
