class AddFileDisksRefToHashFiles < ActiveRecord::Migration
  def change
    add_column :file_disks, :hash_id, :string, limit: 64
    add_foreign_key :file_disks, :hash_files, column: :hash_id
  end
end
