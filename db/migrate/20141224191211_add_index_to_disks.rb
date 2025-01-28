class AddIndexToDisks < ActiveRecord::Migration[8.0]
  def change
    add_index :disks, :name, unique: true
  end
end
