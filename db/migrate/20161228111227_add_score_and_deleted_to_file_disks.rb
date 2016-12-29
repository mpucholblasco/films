class AddScoreAndDeletedToFileDisks < ActiveRecord::Migration
  def change
    add_column :file_disks, :score, :decimal, precision: 5, scale: 2
    add_column :file_disks, :deleted, :boolean, :null => false, :default => false
    add_index :file_disks, :deleted, unique: false
  end
end
