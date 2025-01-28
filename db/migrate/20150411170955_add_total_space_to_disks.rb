class AddTotalSpaceToDisks < ActiveRecord::Migration[8.0]
  def change
    add_column :disks, :total_size, :bigint
    add_column :disks, :free_size, :bigint
  end
end
