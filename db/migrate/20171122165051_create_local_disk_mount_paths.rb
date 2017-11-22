class CreateLocalDiskMountPaths < ActiveRecord::Migration
  def change
    create_table :local_disk_mount_paths do |t|
      t.string :path
      t.references :disk, disk: true, index: true

      t.timestamps null: false
    end
    add_foreign_key :local_disk_mount_paths, :disks
  end
end
