class AddLastSyncDateToDisks < ActiveRecord::Migration
  def change
    add_column :disks, :last_sync, :datetime
  end
end
