class CreateFileDisks < ActiveRecord::Migration[8.0]
  def change
    create_table :file_disks do |t|
      t.string :filename
      t.integer :size_mb
      t.references :disk, index: true

      t.timestamps null: false
    end
    add_foreign_key :file_disks, :disks
  end
end
