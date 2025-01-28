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

ActiveRecord::Schema[8.0].define(version: 2016_12_28_111227) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "disk_type", ["HD", "DVD", "CD"]
  create_enum "job_finish_status", ["UNFINISHED", "FINISHED_WITH_ERRORS", "FINISHED_CORRECTLY", "CANCELLED"]

  create_table "disks", force: :cascade do |t|
    t.string "name"
    t.enum "disk_type", enum_type: "disk_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_sync"
    t.bigint "total_size"
    t.bigint "free_size"
    t.index ["name"], name: "index_disks_on_name", unique: true
  end

  create_table "downloads", force: :cascade do |t|
    t.string "filename"
    t.float "percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "file_disks", force: :cascade do |t|
    t.string "filename"
    t.integer "size_mb"
    t.bigint "disk_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "score", precision: 5, scale: 2
    t.boolean "deleted", default: false, null: false
    t.index ["deleted"], name: "index_file_disks_on_deleted"
    t.index ["disk_id", "filename"], name: "index_file_disks_on_disk_id_and_filename", unique: true
    t.index ["disk_id"], name: "index_file_disks_on_disk_id"
  end

  create_table "jobs", id: :string, force: :cascade do |t|
    t.integer "progress_max", default: 100, null: false
    t.integer "progress", default: 0, null: false
    t.string "progress_stage"
    t.enum "finish_status", default: "UNFINISHED", null: false, enum_type: "job_finish_status"
    t.text "error_message"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "update_stats", force: :cascade do |t|
    t.string "name"
    t.integer "update_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_update_stats_on_name", unique: true
  end

  add_foreign_key "file_disks", "disks"
end
