class AddIndexToFileDisk < ActiveRecord::Migration
  def change
    add_index :file_disks, [:disk_id, :filename], unique: true
  end
end
