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

ActiveRecord::Schema.define(version: 20150123112755) do

  create_table "disks", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "disk_type",  limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "disks", ["name"], name: "index_disks_on_name", unique: true, using: :btree

  create_table "downloads", force: :cascade do |t|
    t.string   "filename",   limit: 255
    t.float    "percentage", limit: 24
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "file_disks", force: :cascade do |t|
    t.string   "filename",   limit: 255
    t.integer  "size_mb",    limit: 4
    t.integer  "disk_id",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "file_disks", ["disk_id", "filename"], name: "index_file_disks_on_disk_id_and_filename", unique: true, using: :btree
  add_index "file_disks", ["disk_id"], name: "index_file_disks_on_disk_id", using: :btree

  create_table "update_stats", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.integer  "update_count", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "update_stats", ["name"], name: "index_update_stats_on_name", unique: true, using: :btree

  add_foreign_key "file_disks", "disks"
end
