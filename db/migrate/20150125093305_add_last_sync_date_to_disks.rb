class AddLastSyncDateToDisks < ActiveRecord::Migration[8.0]
  def change
    add_column :disks, :last_sync, :datetime
  end
end
