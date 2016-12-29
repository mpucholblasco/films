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

ActiveRecord::Schema.define(version: 20161228111227) do

  create_table "delayed_job_progresses", primary_key: "job_id", force: :cascade do |t|
    t.integer  "progress_max",   limit: 4,   null: false
    t.integer  "progress",       limit: 4,   null: false
    t.string   "progress_stage", limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "disks", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "disk_type",  limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "last_sync"
    t.integer  "total_size", limit: 8
    t.integer  "free_size",  limit: 8
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
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.decimal  "score",                  precision: 5, scale: 2
    t.boolean  "deleted",    limit: 1,                           default: false, null: false
  end

  add_index "file_disks", ["deleted"], name: "index_file_disks_on_deleted", using: :btree
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
