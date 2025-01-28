class AddIndexToFileDisk < ActiveRecord::Migration[8.0]
  def change
    add_index :file_disks, [ :disk_id, :filename ], unique: true
  end
end
