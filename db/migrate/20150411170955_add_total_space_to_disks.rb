class AddTotalSpaceToDisks < ActiveRecord::Migration
  def change
    add_column :disks, :total_size, :bigint
    add_column :disks, :free_size, :bigint
  end
end
