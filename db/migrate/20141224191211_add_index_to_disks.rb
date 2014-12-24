class AddIndexToDisks < ActiveRecord::Migration
  def change
    add_index :disks, :name, unique: true
  end
end
