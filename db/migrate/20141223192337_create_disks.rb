class CreateDisks < ActiveRecord::Migration[8.0]
  def change
    create_enum :disk_type, [ "HD", "DVD", "CD" ]

    create_table :disks do |t|
      t.string :name
      t.enum :disk_type, enum_type: :disk_type

      t.timestamps null: false
    end
  end
end
