# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_20_165348) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.text "body"
    t.bigint "story_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["story_id"], name: "index_answers_on_story_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name_game"
    t.json "driving", default: {}, null: false
    t.json "users_joined", default: [], array: true
    t.json "players", default: [], array: true
    t.json "selected_story", default: {}, null: false
    t.integer "id_players_responded", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "invitation_to_the_games", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "game_id", null: false
    t.boolean "to_the_game", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["game_id"], name: "index_invitation_to_the_games_on_game_id"
    t.index ["user_id"], name: "index_invitation_to_the_games_on_user_id"
  end

  create_table "stories", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "game_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["game_id"], name: "index_stories_on_game_id"
  end

  create_table "timers", force: :cascade do |t|
    t.boolean "timer", default: true
    t.integer "timer_time"
    t.bigint "game_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["game_id"], name: "index_timers_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "answers", "stories"
  add_foreign_key "answers", "users"
  add_foreign_key "invitation_to_the_games", "games"
  add_foreign_key "invitation_to_the_games", "users"
  add_foreign_key "stories", "games"
  add_foreign_key "timers", "games"
end
